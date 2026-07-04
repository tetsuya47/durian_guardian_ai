"""AI Agronomist — RAG + LLM Pipeline (Model 4).

Framework structure for retrieval-augmented generation using local LLM (Ollama)
with ChromaDB vector store and durian domain knowledge base.

No training required — uses pre-trained LLM with knowledge retrieval.
"""

from pathlib import Path
from typing import Any, Dict, List, Optional

from training.utils.logger import Logger


class RAGPipeline:
    """Retrieval-Augmented Generation pipeline for AI Agronomist.

    Components:
    - Embedding model (Ollama nomic-embed-text)
    - Vector store (ChromaDB)
    - LLM (Ollama)
    - Prompt templates
    - Knowledge base
    """

    def __init__(self, config: Dict[str, Any]) -> None:
        self.config = config
        self.logger = Logger.get_logger("RAGPipeline")
        self.llm_config = config.get("model", {}).get("llm", {})
        self.rag_config = config.get("rag", {})
        self.embedding_config = config.get("embedding", {})
        self.vector_store_config = config.get("vector_store", {})
        self.knowledge_config = config.get("knowledge_base", {})
        self.prompt_templates = config.get("prompt_templates", {})

        self.embedding_model = None
        self.vector_store = None
        self.llm = None

    def initialize(self) -> None:
        """Initialize all RAG components. Call once before use."""
        self._init_embeddings()
        self._init_vector_store()
        self._init_llm()
        self.logger.info("RAGPipeline initialized")

    def _init_embeddings(self) -> None:
        provider = self.embedding_config.get("provider", "ollama")
        model_name = self.embedding_config.get("model_name", "nomic-embed-text")

        if provider == "ollama":
            try:
                from langchain_ollama import OllamaEmbeddings
                self.embedding_model = OllamaEmbeddings(
                    model=model_name,
                    base_url=self.llm_config.get("base_url", "http://localhost:11434"),
                )
                self.logger.info("Embeddings: %s/%s", provider, model_name)
            except ImportError:
                self.logger.warning("langchain-ollama not installed. pip install langchain-ollama")

    def _init_vector_store(self) -> None:
        store_type = self.vector_store_config.get("type", "chromadb")
        collection_name = self.vector_store_config.get("collection_name", "dga_knowledge_base")
        persist_dir = self.vector_store_config.get("persist_directory",
                                                     "training/models/llm/vector_store")

        if self.embedding_model is None:
            self.logger.warning("Embeddings not initialized, skipping vector store")
            return

        try:
            import chromadb
            from langchain_chroma import Chroma

            persist_path = Path(persist_dir)
            persist_path.mkdir(parents=True, exist_ok=True)

            self.vector_store = Chroma(
                collection_name=collection_name,
                embedding_function=self.embedding_model,
                persist_directory=str(persist_path),
            )
            self.logger.info("Vector store: %s at %s", store_type, persist_dir)
        except ImportError:
            self.logger.warning("chromadb/langchain-chroma not installed")

    def _init_llm(self) -> None:
        provider = self.llm_config.get("provider", "ollama")
        model_name = self.llm_config.get("model_name", "llama3.2")

        if provider == "ollama":
            try:
                from langchain_ollama import ChatOllama
                self.llm = ChatOllama(
                    model=model_name,
                    temperature=self.llm_config.get("temperature", 0.3),
                    max_tokens=self.llm_config.get("max_tokens", 1024),
                    top_p=self.llm_config.get("top_p", 0.9),
                    base_url=self.llm_config.get("base_url", "http://localhost:11434"),
                )
                self.logger.info("LLM: %s/%s", provider, model_name)
            except ImportError:
                self.logger.warning("langchain-ollama not installed")

    def ingest_knowledge(self) -> int:
        """Load knowledge base documents into vector store."""
        if self.vector_store is None:
            self.logger.error("Vector store not initialized")
            return 0

        from langchain.text_splitter import RecursiveCharacterTextSplitter
        from langchain_community.document_loaders import TextLoader, DirectoryLoader

        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.rag_config.get("chunk_size", 512),
            chunk_overlap=self.rag_config.get("chunk_overlap", 64),
        )

        total_chunks = 0
        sources = self.knowledge_config.get("sources", [])

        for source in sources:
            source_path = Path(source["path"])
            if not source_path.exists():
                self.logger.warning("Knowledge source not found: %s", source_path)
                continue

            try:
                if source_path.is_file():
                    loader = TextLoader(str(source_path))
                else:
                    loader = DirectoryLoader(
                        str(source_path),
                        glob="**/*.md",
                        show_progress=True,
                    )

                documents = loader.load()
                chunks = text_splitter.split_documents(documents)
                if chunks:
                    self.vector_store.add_documents(chunks)
                    total_chunks += len(chunks)
                    self.logger.info("Ingested %s: %d chunks", source_path, len(chunks))
            except Exception as exc:
                self.logger.warning("Failed to ingest %s: %s", source_path, exc)

        self.logger.info("Knowledge ingestion complete: %d total chunks", total_chunks)
        return total_chunks

    def query(self, question: str, context: Optional[Dict[str, Any]] = None,
              template_key: str = "general_advice") -> str:
        """Query the AI Agronomist with RAG.

        Args:
            question: User question.
            context: Additional context (symptoms, weather, etc.).
            template_key: Prompt template to use.

        Returns:
            LLM response string.
        """
        if self.llm is None:
            return "LLM not initialized. Call initialize() first."

        retrieved_context = ""
        if self.vector_store is not None:
            top_k = self.rag_config.get("top_k", 5)
            try:
                docs = self.vector_store.similarity_search(question, k=top_k)
                retrieved_context = "\n\n".join(doc.page_content for doc in docs)
            except Exception as exc:
                self.logger.warning("Retrieval failed: %s", exc)

        template = self.prompt_templates.get(template_key, self.prompt_templates.get("general_advice", ""))
        prompt = template.format(context=retrieved_context, question=question, **(context or {}))

        try:
            from langchain_core.messages import HumanMessage
            messages = [HumanMessage(content=prompt)]
            response = self.llm.invoke(messages)
            return response.content
        except Exception as exc:
            self.logger.error("LLM query failed: %s", exc)
            return f"Error: {exc}"

    def diagnose(self, symptoms: str, variety: str = "",
                 weather: str = "") -> str:
        """Diagnose durian disease based on symptoms."""
        context = {"symptoms": symptoms, "variety": variety, "weather": weather}
        return self.query(
            question=f"Diagnose disease with symptoms: {symptoms}",
            context=context,
            template_key="disease_diagnosis",
        )

    def ask_treatment(self, question: str) -> str:
        """Ask about treatment recommendations."""
        return self.query(question=question, template_key="treatment_query")

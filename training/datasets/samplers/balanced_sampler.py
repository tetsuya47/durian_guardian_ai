"""Dataset samplers for handling class imbalance."""

from typing import Iterator, Optional

import numpy as np
import torch
from torch.utils.data import Dataset, Sampler, WeightedRandomSampler


class BalancedBatchSampler(Sampler):
    """Yields batches with balanced class distribution.

    Useful for handling imbalanced datasets during training.
    """

    def __init__(
        self,
        dataset: Dataset,
        labels: Optional[torch.Tensor] = None,
        batch_size: int = 32,
        drop_last: bool = False,
    ) -> None:
        self.dataset = dataset
        self.batch_size = batch_size
        self.drop_last = drop_last

        if labels is not None:
            self.labels = labels
        else:
            try:
                self.labels = torch.tensor([dataset[i][1] for i in range(len(dataset))])
            except Exception:
                raise ValueError("Cannot extract labels from dataset")

        class_counts = torch.bincount(self.labels)
        class_weights = 1.0 / class_counts.float()
        sample_weights = class_weights[self.labels]
        self.weighted_sampler = WeightedRandomSampler(
            weights=sample_weights,
            num_samples=len(sample_weights),
            replacement=True,
        )

    def __iter__(self) -> Iterator:
        batch = []
        for idx in self.weighted_sampler:
            batch.append(idx)
            if len(batch) == self.batch_size:
                yield batch
                batch = []
        if len(batch) > 0 and not self.drop_last:
            yield batch

    def __len__(self) -> int:
        if self.drop_last:
            return len(self.dataset) // self.batch_size
        return (len(self.dataset) + self.batch_size - 1) // self.batch_size


class StratifiedSampler(Sampler):
    """Stratified sampler that preserves class distribution in each batch."""

    def __init__(
        self,
        labels: torch.Tensor,
        batch_size: int,
        num_classes: int,
        drop_last: bool = False,
    ) -> None:
        self.labels = labels
        self.batch_size = batch_size
        self.num_classes = num_classes
        self.drop_last = drop_last
        self.indices_per_class = self._build_indices()

    def _build_indices(self) -> dict:
        indices = {}
        for class_id in range(self.num_classes):
            indices[class_id] = torch.where(self.labels == class_id)[0].tolist()
        return indices

    def __iter__(self) -> Iterator:
        per_class = self.batch_size // self.num_classes
        extra = self.batch_size % self.num_classes
        remaining = {k: list(v) for k, v in self.indices_per_class.items()}

        batch = []
        while True:
            for class_id in range(self.num_classes):
                num_samples = per_class + (1 if class_id < extra else 0)
                if len(remaining[class_id]) < num_samples:
                    yield from self._flush_batch(batch)
                    batch = []
                    remaining = {k: list(v) for k, v in self.indices_per_class.items()}
                for _ in range(num_samples):
                    if remaining[class_id]:
                        idx = remaining[class_id].pop(0)
                        batch.append(idx)
            if len(batch) >= self.batch_size:
                yield batch[:self.batch_size]
                batch = batch[self.batch_size:]
            if all(len(v) == 0 for v in remaining.values()):
                if batch and not self.drop_last:
                    yield batch
                break

    def _flush_batch(self, batch: list) -> list:
        if batch:
            yield batch
        return []

    def __len__(self) -> int:
        total = len(self.labels)
        if self.drop_last:
            return total // self.batch_size
        return (total + self.batch_size - 1) // self.batch_size

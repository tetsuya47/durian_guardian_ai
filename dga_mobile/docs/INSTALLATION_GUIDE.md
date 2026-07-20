# Installation Guide

## Backend Setup
1. **Requirements**: Python 3.10+ and MongoDB instance.
2. **Install Dependencies**:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
3. **Configure Environment**: Create `.env` file:
   ```env
   MONGODB_URL=mongodb://localhost:27017
   MONGODB_DB_NAME=durian_guardian_ai
   JWT_SECRET_KEY=dev-secret-key-change-in-production
   ```
4. **Run Server**:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

## Frontend Setup
1. **Requirements**: Flutter SDK 3.19+ (stable).
2. **Install Packages**:
   ```bash
   flutter pub get
   ```
3. **Run Application**:
   ```bash
   flutter run
   ```

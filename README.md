# Supply Chain LLMOps Case Study 🚛📦

An AI-driven Natural Language Interface for querying supply chain data, demonstrating advanced LLMOps practices including RAG, Code Generation (Python/SQL), LLM-as-a-judge evaluation, and Azure cloud deployment.

## 🌟 Key Features
- **Natural Language Querying**: Ask questions about orders, risk, and financials in plain English.
- **Dual-Mode Generation**: Automatically selects between **Python** (Pandas) for complex analysis and **SQL** (DuckDB) for efficient retrieval.
- **LLM-as-a-Judge**: Validates generated code for safety and correctness before execution.
- **RAG Pipeline**: Retrieves relevant context from vector store for enhanced responses.
- **Azure Deployment**: Fully deployed to Azure App Service with containerized Docker image.

## 💡 Sample Queries
Try these queries to explore the dataset:
- "What is the total sales?"
- "Which shipping mode has the highest average profit?"
- "List the top 5 product categories by sales."
- "Show a line chart showing the revenue/ sales over the time periods."
- "Show a bar chart showing the total sales by market."
- "Show a pie chart showing the total sales by product category."

**Vector Store**: Uses **Azure AI Search** for production deployment with separate embedding configuration.

## 📂 Project Structure
- `src/`: Source code including **Streamlit** client (`app.py`), chain logic (`chain.py`), configuration (`config.py`), data ingestion (`ingestion.py`), SQL tools (`sql_tools.py`), and vector store abstraction (`vector_store.py`).
- `prompts/`: Managed prompts (`.prompty` files) for all LLM interactions (intent classification, code generation, code evaluation, SQL generation, response synthesis).
- `data/`: Real-world datasets (`DataCoSupplyChainDataset.csv`), domain knowledge (`domain_knowledge.txt`), and evaluation triples (`golden_dataset.json`).
- `evaluations/`: Ragas evaluation scripts.
- `nra_deployment_script.sh`: Custom Azure deployment script.
- `nra_deployment_cleanup.sh`: Azure resource cleanup script.
- `nra_deployment_readme.md`: Detailed deployment documentation.
- `nra_setup.env`: Azure resource configuration for deployment.

### Create Python Virtual Environment
Ensure you've created a python virtual environment 
```bash
python -m venv venv
```
### Activate Python virtual environment
For Mac/ Linux enter the following command:
```bash
source venv/bin/activate
```
For Windows systems, enter the following command:
```bash
venv/Scripts/activate
```
### Install Libraries
```bash
pip install -r requirements.txt
```

### Running the App
Ensure your `.env` file is configured with the necessary API keys.
```bash
streamlit run src/app.py
```
The app will be available at `http://localhost:8501`.

### Running Evaluations

To evaluate the RAG pipeline using Ragas:
```bash
python evaluations/eval_script.py
```

### Code Quality & Linting

This project uses modern Python code quality tools configured in `pyproject.toml`:

#### Code Formatting
**Black** - Automatic code formatting to PEP 8 compliance:
```bash
# Check formatting
black --check src tests

# Auto-format code
black src tests
```

#### Linting
**Ruff** - Fast, comprehensive Python linter (includes Flake8, isort, pyupgrade):
```bash
# Run linting
ruff check src tests

# Auto-fix issues
ruff check --fix src tests
```


**Note**: All tools are configured in `pyproject.toml` with:
- Line length: 100 characters
- Target Python version: 3.11
- Import sorting enabled (isort via Ruff)

## Azure Deployment

This project has been successfully deployed to Azure using custom deployment scripts.

### Deployed Application
- **URL**: https://nra-webapp.azurewebsites.net
- **Platform**: Azure App Service (Linux, Python 3.10)
- **Container**: Docker image deployed via Azure Container Registry

### Azure Resources Created
- **Resource Group**: `rgrp`
- **Azure Storage Account**: `nrastorageacc` with blob container
- **Azure AI Search**: `nra-ai-search` with supply-chain index
- **Azure Container Registry**: `nracontainerregistry`
- **Azure App Service Plan**: B1 tier
- **Azure App Service**: `nra-webapp`

### Deployment Instructions
See `nra_deployment_readme.md` for detailed deployment instructions including:
- Prerequisites (Azure CLI, Docker Desktop)
- Environment configuration
- Running the deployment script
- Troubleshooting

### Deployment Scripts
- `nra_deployment_script.sh`: Automated Azure resource provisioning and deployment
- `nra_deployment_cleanup.sh`: Azure resource cleanup
- `nra_setup.env`: Azure resource configuration variables

## Models Used

### Azure OpenAI Deployments
- **gpt-5-mini**: Used for intent classification, code generation (Python/SQL), code evaluation (LLM Judge), and response synthesis
  - Endpoint: `https://nitin-mlwodxs0-eastus2.openai.azure.com/`
  - API Version: `2024-08-01-preview`
  - Temperature: `1.0` (required by gpt-5-mini, only supports default value)

- **text-embedding-3-small**: Used for RAG embeddings
  - Endpoint: `https://myhub0305631040.openai.azure.com/` (separate Azure OpenAI account)
  - API Version: `2024-02-01`

### Configuration Notes
- The embedding model is hosted in a separate Azure OpenAI account from the main model
- gpt-5-mini only supports temperature=1.0 (default), which is used for all LLM calls
- Separate embedding endpoint, key, and API version are configured in the application

## 🔧 Deployment Fixes & Troubleshooting

### Issues Resolved During Deployment

1. **Azure Search Credentials Missing**
   - Added AZURE_SEARCH_ENDPOINT and AZURE_SEARCH_KEY to Web App environment variables
   - Updated deployment script to validate and set these credentials automatically

2. **DeploymentNotFound Error**
   - Updated AZURE_OPENAI_API_VERSION to `2024-08-01-preview`
   - Added deployment validation check in deployment script

3. **Embedding Model in Separate Account**
   - Discovered embedding deployment (text-embedding-3-small) is in different Azure OpenAI account
   - Added separate embedding endpoint, key, and API version configuration
   - Updated vector_store.py to use separate embedding endpoint when configured

4. **Temperature Parameter Error**
   - gpt-5-mini only supports temperature=1.0 (default value)
   - Updated judge LLM temperature from 0.0 to 1.0 in chain.py

5. **Missing Domain Knowledge File**
   - Created domain_knowledge.txt with supply chain domain information
   - Uploaded to Azure Storage for RAG context

6. **Hardcoded Model Configurations**
   - Removed hardcoded model configurations from prompty files
   - Prompty files now use runtime configuration from environment variables

### Performance Notes
- The application is functional but queries may take time due to:
  - Large CSV file (95MB) loading
  - Multiple LLM API calls per query (intent, generation, evaluation, synthesis)
  - Vector store operations
- Consider using a smaller dataset subset for faster testing
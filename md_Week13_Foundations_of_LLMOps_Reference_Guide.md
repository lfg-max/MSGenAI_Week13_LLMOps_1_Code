# Foundations of LLMOps [MLS Reference Guide]

**Case Study - DataCo Supply Chain Copilot**

## Problem Statement
* DataCo is a multinational logistics and e-commerce company handling millions of orders annually across clothing, sports, electronics, and other categories.
* The company maintains a rich operational database capturing every aspect of the supply chain-from order placement and product details to shipping modes, delivery dates, customer locations, payment methods, sales revenue, profit margins, returns, and fraud risk signals.
* Despite this wealth of data stored in relational databases (i.e. SQL database records), critical business insights remain difficult to access quickly and requires deep expertise in SQL and Python, creating a significant insight bottleneck.
* Business leaders-from warehouse supervisors to regional directors are forced to wait for overstretched analysts to provide answers to time-sensitive, ad-hoc questions. This delay results in missed opportunities to mitigate fraud, optimize shipping costs, and improve delivery performance in a competitive global market.
* This diverse data requires careful analysis and typically involves writing SQL or Python queries for getting precise answers to queries, a time-intensive task typically done by business analysts in the company.

Supply chain managers, regional directors, warehouse supervisors, and fraud prevention teams frequently need answers to complex, ad-hoc questions such as:
* "Which regions have the highest late-delivery rates in the last quarter, and what shipping modes are most affected?"
* "What product categories show the largest profit loss due to returns, grouped by customer segment?"
* "Are there unusual order patterns indicating potential fraud in high-value electronics shipments to specific countries?"
* "How would switching to faster shipping modes impact overall delivery performance and costs in North America?"

The reliance on a small pool of analysts creates a "queue" system which leads to a decision latency-by the time an answer is delivered, the opportunity to prevent a late shipment or catch a fraudster may have passed.

## Business Objective
* The primary objective is to build an Al-Driven Natural Language Interface that incorporates code capability via LLMs to democratize data access across the logistics organization.
* The primary objective is to eliminate the technical barrier to data access, reducing the time-to-insight from days to seconds.
* This will enable stakeholders to perform self-service diagnostic analytics, thereby improving operational efficiency, reducing fraud-related losses, and optimizing shipping costs through real-time data exploration.
* The system must not only provide answers but also return the underlying logic (Python/ SQL) and source citations to ensure data governance and auditability.
* The system should be able to dynamically retrieve relevant schema information, example queries to ground its output.

## Azure Services
We'll use the following Azure services for this case study:
* **Azure Al Foundry:** to access the language models used in the pipeline
* **Azure Prompt Flow:** to create and manage LLM workflows to ensure reliable, production-ready pipelines
* **Azure Container Registry:** to store and manage private Docker container images, enabling the seamless deployment of the application code and custom workflow environments.
* **Azure App Services:** to host the final web-based Chatbot interface, providing a scalable and secure platform for end-users to submit natural language queries and view data insights.
* **GitHub:** to serve as the main repository for storing the codes and data artifacts

## MLS Resources
The MLS case study requires the following resources:
* An active Azure Resource Group
* Azure Al Foundry (hub-based project) with OpenAl model deployments
* Azure Container Registry (ACR)
* Azure App Services
* Azure CLI
* Docker (Docker CLI)

## Important Points to Note
Ground rules for setting up an Azure Al Foundry:
* Utilize the default resource group for all your tasks
* Avoid creating multiple groups to ensure consistency, simplify monitoring, and reduce overhead
* Select Region = East US for the Azure Al Foundry
* Allow 10 to 15 minutes for the resource to become fully operational following its creation

## Deploying Models & Al Service
### Model Selection
For this case study, model selection plays a crucial role in balancing performance, accuracy, and cost efficiency. Choosing the right combination of models directly impacts the quality of retrieval, response relevance, and overall system scalability within the RAG pipeline.

* **Language Model - gpt-5-mini:** The selected generation model, gpt-5-mini, provides an optimal balance between computational efficiency and language fluency.
* **Judge Model - gpt-4.1:** This model will be used as the Judge Model (or Evaluation Model) to evaluate the outputs of the main LLM and verify its outputs before the code execution is performed.
* **Embedding Model - text-embedding-3-small:** This model will be used as the embedding model to embed input documents for the RAG pipeline.

### Deployment Steps
1. Select 'gpt-5-mini' from Model catalog
2. Select 'Use this model'
3. Select 'Direct from Azure models' under Purchase options
4. Click 'Create resource and deploy'
5. Model 'gpt-5-mini' has been successfully created.
6. Select 'gpt-4.1' from Model catalog
7. Select 'Use this model'
8. Select "Direct from Azure models"
9. Click "Deploy" to deploy the model
10. Model has been deployed

## Docker Recap
### Docker Workflow
* A developer creates an app or service and packages it and its dependencies into a container image - which is a static representation of the app or service and its configuration and dependencies.
* To run the app or service, the app's image is instantiated to create a container, which will be running on the Docker host.
* Containers are initially tested in a development environment locally.
* These are then stored in a container registry, that acts as as a library of images and where images are stored and available to be pulled for building containers to run services or web apps.
* Private registry include Docker Hub, Docker Trusted Registry (for enterprises), and Azure Container Registry.

## Azure Container Registry (ACR) Service
* Azure Container Registry (ACR) is a fully managed, private Docker registry service in Azure that allows you to build, store, secure, and manage container images and related artifacts for containerized applications with full push/pull support using standard Docker commands.
* It provides a seamless integration with Azure services like Azure App Service, Azure Container Service, Azure Kubernetes Service (AKS), and DevOps pipelines, enabling streamlined container development and deployment workflows.
* ACR significantly reduces operational overhead by providing a robust, scalable container image management platform that supports enterprise-grade security, compliance, and global scalability, making it ideal for organizations leveraging containers in Azure.
* An Azure container registry stores and manages private container images and other artifacts, similar to the way Docker Hub stores public Docker container images. You can use the Docker command-line interface (Docker CLI) for login, push, pull, and other container image operations on your container registry.

### Creating ACR
1. Click on "More services" in Azure Portal.
2. Search "Container Registries" and select "Container Registries".
3. Click Create to create a new container registry.
4. Enter the details (Resource group, Registry name, Region: East US, Pricing plan: Basic) and click on "Review + create".
5. Review the configuration details and click "Create".
6. The Azure Container Registry has been created.
7. Navigate to Access Keys in Setting and check "Admin user".
8. Copy and note the Username and the password for the Container Registry. This will be used to login to Azure Container Registry service from VS Code.

## Creating GitHub Repo
1. Login to Github and navigate to the GitHub Dashboard.
2. Click on "New" to create a new repository.
3. Enter the details and click on "Create repository".
4. Click on "Code".
5. Click "Code" and select "Create codespace on main".
6. A VS Code environment is created on the main branch of the repository.

## VS Code Environment Setup
1. Install Container Tools Extension.
2. Install Azure Resources Extension.
3. Install Docker (if not already installed).

## Code Deployment Walkthrough
1. Upload the Project files to GitHub Codespaces.
2. The project structure follows the Microsoft GenAlOps template that recommends using a standardized project structure to organizes generative Al code into modular directories to enable teams to develop, test, and deploy generative Al applications with consistent organization and clear boundaries between experimentation and production code.
    * `src` contains the main source code (orchestration, models, utilities)
    * `evaluations` contains the evaluation scripts and metrics
    * `data` contains the datasets for training and evaluation
    * `prompts` contains the prompt templates
    * `infra` - Infrastructure-as-Code template (this is not included in this MLS)
    * `tests` contains the Python code for unit, integration and end-to-end tests (this is not included in this MLS)
    * `docs` contains the documentation and guides for the application

## Source Control in VS Code
Visual Studio Code has integrated source control management (SCM) that lets you work with Git and other version control systems directly in your editor. The integrated source control interface provides access to Git functionality through a graphical interface instead of terminal commands. You can perform Git operations like staging changes, committing files, creating branches, and resolving merge conflicts without switching to the command line.

**Common Workflow 1 - Stage and commit changes:**
1. Review your changes in the Source Control view.
2. Staging files - VS code automatically stages the files to stage all changes at once. Alternatively, you can select the + icon next to each file.
3. Type your commit message in the input box in the commit message input box.
4. Press "Commit" to commit the codes to the GitHub repository.
5. Click "Yes" to stage and commit directly if no changes were explicitly staged.

**Common Workflow 2 - Sync with remotes:**
1. In the VS Code Source Control extension, `main (Local)` is the branch physically on your computer, and `origin/main (Remote)` is the "tracking branch" representing the last known state on GitHub.
2. Click "Sync Changes" to sync the changes with the remote repo.
3. Click "OK" to perform the push and pull operations on the Git repo.
4. You can view commit history for a visual representation.

**Source Control - Best Practices**
* Commit Early and Often
* Write Descriptive Messages
* Sync Changes Regularly

## Environment Configuration
1. Create a `.env` file from the sample environment file provided (`.env.example`).
2. Add necessary API Keys and Endpoints.

## Create Python Virtual Environment
1. Open a Terminal window.
2. Use the command `python -m venv venv` to create a virtual environment.
3. Activate Python virtual environment:
    * Mac/Linux: `source venv/bin/activate`
    * Windows: `venv/Scripts/activate`
4. Install Libraries: `pip install -r requirements.txt`

## Running the App
1. Ensure your `.env` file is configured with the necessary API keys.
2. Run the application: `streamlit run src/app.py`
3. The app will be available at http://localhost:8501.
4. Navigate to Ports and click Open in Browser.
5. Stop the running streamlit application by using `Ctrl + C` on keyboard.

## Dockerizing the App
1. Verify the `Dockerfile` details.
2. Build the docker image using the `docker build` command: `docker build -t dataco .`
3. Alternatively, right click on the Dockerfile and select Build Image.
4. Verify the docker image has been created using `docker images`.
5. Navigate to the Containers Extension in VS Code.
6. Test the container by using the docker run command: `docker run -p 8501:8501 --env-file .env dataco`
7. Click on the Forwarded Port and Open in Browser.

## Azure Extension Setup & App Services
1. Navigate to Azure Resources extension and click Sign in to Azure.
2. Follow the authentication flow.
3. Navigate to Container Tools Extension in VS Code, click "Connect Registry", select Azure, and login using Azure credentials (or `docker login`).
4. Push the Docker Image to Azure Container Registry.
5. Go to Azure Portal -> App Services.
6. Create a Web App. Choose Basic B1 tier. Under Container, specify your ACR and Image details.
7. Add Environment Variables (e.g., `WEBSITES_PORT=8501`) under Settings.
8. Access the App using the Default domain URL provided.

## Conclusion: Key Takeaways and Business Impact
* By using LLMs to translate human questions into executable code, DataCo removes the technical barrier between complex operational data and the decision-makers.
* By feeding the LLM relevant schema metadata, example queries, and domain-specific terms, the system ensures that the generated code is technically correct and contextually accurate for the logistics domain.
* The AI tool moves the company toward predictive logistics, where they can simulate cost-benefit scenarios instantly.
* By utilizing Azure App Services and Container Registry, the solution highlights that AI tools for logistics must be scalable.

**Expected Business Outcomes:**
* Faster Decision Cycles
* Late-Delivery Mitigation
* Logistics Optimization
* Profit Margin Protection
* Data Democratization

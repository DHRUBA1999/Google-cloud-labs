
#!/bin/bash

# Define required color variables
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# Define color arrays
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($(tput setab 1) $(tput setab 2) $(tput setab 3) $(tput setab 4) $(tput setab 5) $(tput setab 6))

# Pick random text and background colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Header
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}                    Cloud Run Setup Script               ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Enable Cloud Run API
echo "${CYAN}${BOLD}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com

# Clone repo
echo "${GREEN}${BOLD}Cloning Google Cloud generative AI repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/generative-ai.git

# Navigate to required directory
echo "${YELLOW}${BOLD}Navigating to the 'gemini-streamlit-cloudrun' directory...${RESET}"
cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

# Remove existing files
echo "${BLUE}${BOLD}Removing existing files...${RESET}"
rm -rf Dockerfile chef.py requirements.txt

# Download required files
echo "${RED}${BOLD}Downloading required files...${RESET}"
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/chef.py
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/Dockerfile
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/requirements.txt

# Upload to Cloud Storage
echo "${CYAN}${BOLD}Uploading 'chef.py' to Cloud Storage...${RESET}"
gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/

# Set variables
echo "${GREEN}${BOLD}Setting project and region variables...${RESET}"
GCP_PROJECT=$(gcloud config get-value project)
GCP_REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Virtual environment setup
echo "${YELLOW}${BOLD}Setting up virtual environment...${RESET}"
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m pip install -r requirements.txt

# Run Streamlit app
echo "${MAGENTA}${BOLD}Running Streamlit app in background...${RESET}"
nohup streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port=8080 > streamlit.log 2>&1 &

# Create Artifact Registry
echo "${BLUE}${BOLD}Creating Artifact Registry...${RESET}"
AR_REPO='chef-repo'
SERVICE_NAME='chef-streamlit-app'
gcloud artifacts repositories create "$AR_REPO" --location="$GCP_REGION" --repository-format=Docker

# Submit Cloud Build
echo "${RED}${BOLD}Submitting Cloud Build...${RESET}"
gcloud builds submit --tag "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME"

# Deploy to Cloud Run
echo "${CYAN}${BOLD}Deploying Cloud Run service...${RESET}"
gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$GCP_REGION \
  --platform=managed  \
  --project=$GCP_PROJECT \
  --set-env-vars=GCP_PROJECT=$GCP_PROJECT,GCP_REGION=$GCP_REGION

# Get and print service URL
CLOUD_RUN_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$GCP_REGION" --format='value(status.url)')
echo "${YELLOW}${BOLD}Streamlit running at: ${RESET}http://localhost:8080"
echo "${MAGENTA}${BOLD}Cloud Run URL: ${RESET}$CLOUD_RUN_URL"

# Cleanup
remove_files() {
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            [[ -f "$file" ]] && rm "$file" && echo "File removed: $file"
        fi
    done
}
remove_files

cd

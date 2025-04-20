#!/bin/bash

# Text styling variables
BLUE_TEXT=$'\033[0;94m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}Starting execution...${RESET_FORMAT}"
echo

# Read Region Input
read -p "${BLUE_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
echo "${GREEN_TEXT}${BOLD_TEXT}You have entered: ${REGION}${RESET_FORMAT}"
echo

# Get project ID
ID="$(gcloud projects list --format='value(PROJECT_ID)')"

# Create Python script to generate image
cat > GenerateImage.py <<EOF_END
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(project_id, location, output_file, prompt):
  vertexai.init(project=project_id, location=location)
  model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
  images = model.generate_images(prompt=prompt, number_of_images=1, seed=1, add_watermark=False)
  images[0].save(location=output_file)

generate_image(
  project_id='$ID',
  location='$REGION',
  output_file='image.jpeg',
  prompt='Create an image of a cricket ground in the heart of Los Angeles',
)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Generating image...${RESET_FORMAT}"
/usr/bin/python3 /home/student/GenerateImage.py
echo "${GREEN_TEXT}${BOLD_TEXT}Image generated: image.jpeg${RESET_FORMAT}"

# Create Python script for multimodal text generation
cat > genai.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part

def generate_text(project_id, location):
  vertexai.init(project=project_id, location=location)
  model = GenerativeModel("gemini-2.0-flash-001")
  response = model.generate_content([
    Part.from_uri("gs://generativeai-downloads/images/scones.jpg", mime_type="image/jpeg"),
    "what is shown in this image?"
  ])
  return response.text

project_id = "$ID"
location = "$REGION"
print(generate_text(project_id, location))
EOF_END

# Run multimodal model twice with a delay
for i in {1..2}; do
  echo "${YELLOW_TEXT}${BOLD_TEXT}Processing multimodal model (Run $i)...${RESET_FORMAT}"
  /usr/bin/python3 /home/student/genai.py
  if [ $i -eq 1 ]; then sleep 30; fi
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Lab completed successfully!${RESET_FORMAT}"

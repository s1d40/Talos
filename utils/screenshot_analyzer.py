import os
from google import genai
from google.genai import types
from dotenv import load_dotenv
from PIL import Image

# Load environment variables
load_dotenv()

def analyze_screenshot(image_path: str, prompt: str = "Analyze this trading chart. What are the key support and resistance levels, and what is the overall trend?") -> str:
    """
    Analyzes a screenshot using Gemini Vision API.
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return "Error: GEMINI_API_KEY environment variable not set."

    client = genai.Client(api_key=api_key)

    try:
        # Load the image
        img = Image.open(image_path)

        # Generate the response
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt, img]
        )

        return response.text
    except Exception as e:
        return f"Error analyzing screenshot: {e}"

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
        print(f"Analyzing {image_path}...")
        result = analyze_screenshot(image_path)
        print(result)
    else:
        print("Please provide an image path as an argument.")

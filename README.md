# Luxe - Exoplanet Discovery Platform 🪐

## About

Luxe is an intelligent platform that makes exoplanet discovery accessible to everyone. We combine machine learning, artificial intelligence, and stunning visualizations to help users identify and explore potential new worlds beyond our solar system.

Our mission is to democratize astronomy by translating complex astronomical data into insights anyone can understand.

## What We Built

Luxe tackles one of astronomy's biggest challenges: identifying exoplanets from vast amounts of celestial data. Our platform uses a machine learning model to predict whether a celestial object is an exoplanet based on its descriptive characteristics, then brings those predictions to life through AI-powered explanations and visualizations.

## Key Features

- **Machine Learning Predictions**: Advanced ML model that analyzes astronomical data to identify potential exoplanets
- **AI-Powered Explanations**: Integration with Gemini API to translate complex predictions into natural language that anyone can understand
- **Visual Discovery**: Hugging Face API generates stunning, predictive images of what these potential new worlds could look like
- **Intuitive Mobile Interface**: Native iOS app built with SwiftUI for seamless exoplanet exploration
- **Real-time Data Processing**: Fast, accurate analysis of celestial object characteristics

## Tech Stack

### Backend
- **Python**: Core backend language for ML model training and API services
- **Flask**: Lightweight web framework for API endpoints
- **scikit-learn**: Machine learning library for exoplanet classification model

### Machine Learning
- Custom ML model for exoplanet classification
- Trained on astronomical datasets
- Configurable hyperparameters (n_estimators, max_depth, random_state)

### AI & APIs
- **Gemini API**: Natural language explanations of predictions and interactive data insights
- **Hugging Face API**: AI-generated exoplanet imagery
- **Google Auth**: Secure API authentication

### Mobile Application
- **Swift & SwiftUI**: Modern, native iOS interface with declarative UI
- **MVVM Architecture**: Clean, maintainable code structure
- **iOS 16+**: Latest platform capabilities
- Native networking for seamless backend communication

### Design System
- Consistent spacing and radius standards
- Semantic color theming
- Reusable UI components (ChartContainer, Theme, etc.)

### Additional Dependencies
- **httpx & requests**: Robust HTTP client libraries
- **pydantic**: Data validation and settings management
- **joblib**: Model persistence and pipeline management

## Getting Started

### Prerequisites

**For the iOS App:**
- Xcode 14.0+
- iOS 16.0+
- Swift 5.7+

**For the Backend/ML Model:**
- Python 3.8+
- Required dependencies (see `requirements.txt`)

### Installation

#### iOS Application

1. Clone the repository
```
git clone https://github.com/yourusername/luxe.git
cd luxe
```
2. Open the iOS project

```HackNasa.xcodeproj```

3. Build and run on your device or simulator

Backend Setup
```cd backend
pip install -r requirements.txt
python app.py
```
## How It Works

### Step 1: Data Upload
Users can obtain exoplanet datasets in CSV format from public astronomical databases provided by organizations like NASA or other space research institutions. These datasets contain descriptive characteristics of celestial objects that our model will analyze.

Once you have your dataset, simply upload it through the app's dedicated data import section.

### Step 2: Model Configuration
Before running the prediction, users can fine-tune three key hyperparameters to optimize the machine learning model's performance:

- **n_estimators**: Controls the number of decision trees in the ensemble (more trees can improve accuracy but increase processing time)
- **max_depth**: Determines how deep each decision tree can grow (affects model complexity and overfitting prevention)
- **random_state**: Ensures reproducibility of results across different runs

The app provides helpful tooltips and explanations for each parameter, making it easy for users to understand how their choices affect the analysis—no prior machine learning knowledge required.

### Step 3: Processing & Analysis
Once configured, our machine learning model processes your dataset:
- Analyzes each celestial object's characteristics
- Applies the trained model with your specified parameters
- Identifies potential exoplanet candidates from your data
- Generates comprehensive prediction results

### Step 4: Visual Results
The app presents your results through intuitive, interactive charts and visualizations that make complex data easy to understand:
- **Statistical Overview**: Charts showing prediction confidence, distribution patterns, and key metrics
- **Exoplanet Gallery**: AI-generated images of the identified exoplanet candidates created using Hugging Face's generative models
- **Data Insights**: Clear visual representations of your dataset's characteristics

### Step 5: AI-Assisted Understanding
This is where Luxe truly shines. Powered by Gemini AI, the app acts as your personal astronomy assistant:
- **Natural Language Explanations**: Ask questions about any data point, chart, or result and receive clear, detailed explanations
- **Deep Dive Analysis**: Get comprehensive descriptions of why certain objects were classified as exoplanets
- **Interactive Learning**: Explore the scientific reasoning behind predictions in conversational, accessible language
- **Custom Insights**: Request specific information about any aspect of your results—from individual exoplanet characteristics to overall dataset patterns

Whether you're a student, educator, amateur astronomer, or simply curious about space, Luxe transforms raw astronomical data into an engaging, educational discovery experience.

### License
This project is licensed under the MIT License - see the LICENSE file for details.

### Acknowledgments
- **NASA** Thank you for inspiring the next generation of space explorers and for providing access to real astronomical data and assets. We're grateful for the opportunity to participate in this challenge and contribute to the future of space discovery.

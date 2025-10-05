import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const KEPLER_OBJECT_NAME = "Kepler-452b";
const MODEL_PREDICTION = "Likely Exoplanet";
const CONFIDENCE_SCORE = "92%";
const KEY_FACTORS = "Orbital period matches expected range, consistent transit signals, and minimal noise in the data.";

export default async function queryGeminiSimpleExplanation() {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: 
        `You are an expert science communicator with the goal of making complex astronomy topics easy to understand.

        A machine learning model analyzed data for a potential exoplanet and produced the following result. Your task is to explain this result in 2-3 simple, engaging sentences for a user on a dashboard. Avoid technical jargon and focus on the meaning of the prediction.

        Here is the data from the model:

        - **Object Name:** ${KEPLER_OBJECT_NAME}
        - **Model Prediction:** ${MODEL_PREDICTION}
        - **Confidence Score:** ${CONFIDENCE_SCORE}
        - **Most Important Reasons for this Prediction:** ${KEY_FACTORS}

        Please provide a long but simple explanation divided in this three main sections: 1) Overview, 2) Key Details, 3) Conclusion.
        Each section should go deep into the topic.
        Your answer should be in spanish and only contain the three sections mentioned, do not add anything else.`,
    config: {
      thinkingConfig: {
        thinkingBudget: 0, // Disables thinking
      },
    }
  });
  console.log(response.text);
  return response.text;
}
import express from 'express';
import geminiSimple from './gemini.js'; // Assuming gemini.js is in the same directory

const app = express();
const PORT = process.env.PORT || 80;

// Middleware
app.use(express.json());

// Basic route
app.get('/', (req, res) => {
    res.send('Hello World from NASA Space Apps Backend!');
});

/* ----- ML Model Interaction Endpoints ----- */

// Data request to ML model (placeholder)
app.post('/predict', async (req, res) => {
    const model = req.body.modelId;
    const inputData = req.body.input;

    const apiURL = `http://${process.env.ML_IP}/predict`; // Example IP from .env
    const response = await fetch(apiURL);

    const prediction = { response, input: inputData };
    res.json(prediction);
});

// Parameter tuning endpoint (placeholder)
app.post('/tune', (req, res) => {
    const params = req.body;
    // TODO: Integrate with ML model for parameter tuning
    // Placeholder for parameter tuning logic
    const tunedParams = { ...params, learningRate: 0.01 };
    res.json(tunedParams);
});

// CSV data upload endpoint (placeholder)
app.post('/upload-csv', (req, res) => {
    // TODO: Handle CSV file upload and process data
    // In a real implementation, you would handle file upload here
    // Placeholder for CSV upload logic
    res.json({ message: 'CSV data received and processed (mock response).' });
});

/* ----- Gemini API Explanation Endpoint ----- */

// Request Gemini explanation
app.get('/gemini/explain', async (req, res) => {
    try {
        const explanation = await geminiSimple();
        res.json({ explanation });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get explanation from Gemini API.' });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
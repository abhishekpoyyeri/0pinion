const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const dbPath = path.join(__dirname, 'db.json');

// Helper to read DB
const readDB = () => {
    try {
        return JSON.parse(fs.readFileSync(dbPath, 'utf8'));
    } catch (e) {
        return {};
    }
};

// Helper to write DB
const writeDB = (data) => {
    fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
};

// --- ROUTES ---

// GET all items in a table
app.get('/:table', (req, res) => {
    const db = readDB();
    const table = req.params.table;
    if (!db[table]) return res.status(404).json({ error: 'Table not found' });
    res.json(db[table]);
});

// GET specific item
app.get('/:table/:id', (req, res) => {
    const db = readDB();
    const table = req.params.table;
    if (!db[table]) return res.status(404).json({ error: 'Table not found' });
    
    const item = db[table].find(i => String(i.id) === String(req.params.id));
    if (!item) return res.status(404).json({ error: 'Item not found' });
    res.json(item);
});

// POST new item
app.post('/:table', (req, res) => {
    const db = readDB();
    const table = req.params.table;
    if (!db[table]) return res.status(404).json({ error: 'Table not found' });

    const newItem = { id: Date.now().toString(), ...req.body };
    db[table].push(newItem);
    writeDB(db);
    res.status(201).json(newItem);
});

// PUT/PATCH update item
const updateHandler = (req, res) => {
    const db = readDB();
    const table = req.params.table;
    if (!db[table]) return res.status(404).json({ error: 'Table not found' });

    const index = db[table].findIndex(i => String(i.id) === String(req.params.id));
    if (index === -1) return res.status(404).json({ error: 'Item not found' });

    // Merge existing item with new data
    const updatedItem = { ...db[table][index], ...req.body, id: req.params.id };
    db[table][index] = updatedItem;
    writeDB(db);
    res.json(updatedItem);
};

app.put('/:table/:id', updateHandler);
app.patch('/:table/:id', updateHandler);

// DELETE item
app.delete('/:table/:id', (req, res) => {
    const db = readDB();
    const table = req.params.table;
    if (!db[table]) return res.status(404).json({ error: 'Table not found' });

    const index = db[table].findIndex(i => String(i.id) === String(req.params.id));
    if (index === -1) return res.status(404).json({ error: 'Item not found' });

    db[table].splice(index, 1);
    writeDB(db);
    res.json({ success: true });
});

const PORT = 3001; // Running on 3001 to avoid conflict with json-server on 3000
app.listen(PORT, () => {
    console.log(`Express Mock Server running on http://localhost:${PORT}`);
});

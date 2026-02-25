import multer from 'multer';

// Simple storage configuration: All files go to 'uploads/' folder

const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});

// Create a single upload middleware instance
export const upload = multer({ storage });

// Example usage for a single file
// app.post('/upload', upload.single('fileFieldName'), (req, res) => { ... });
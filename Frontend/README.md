# Text-to-Speech React Frontend

A beautiful React application for text-to-speech conversion with the same design as the original HTML version.

## 🚀 Features

- **Beautiful UI** - Same gradient design with floating hearts animation
- **React Components** - Modern, maintainable code structure
- **Better Error Handling** - Comprehensive error messages and loading states
- **API Service** - Dedicated service for API calls with retry logic
- **Responsive Design** - Works on desktop and mobile devices
- **Loading States** - Visual feedback during audio generation

## 🛠️ Development

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start development server:**
   ```bash
   npm start
   ```
   Or use the PowerShell script:
   ```powershell
   .\start-dev.ps1
   ```

3. **Open your browser:**
   Navigate to `http://localhost:3000`

### Available Scripts

- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run eject` - Eject from Create React App

## 🏗️ Project Structure

```
Frontend/
├── public/
│   └── index.html          # HTML template
├── src/
│   ├── App.js             # Main React component
│   ├── App.css            # App-specific styles
│   ├── index.js           # React entry point
│   ├── index.css          # Global styles
│   └── services/
│       └── TTSService.js   # API service layer
├── package.json           # Dependencies and scripts
└── README.md             # This file
```

## 🔧 Configuration

### API Endpoint
The API endpoint is configured in `src/services/TTSService.js`:

```javascript
const API_BASE_URL = 'https://4b5jz7mn34.execute-api.us-east-1.amazonaws.com/prod';
```

### Environment Variables
You can use environment variables for different environments:

1. Create `.env.local` for local development:
   ```
   REACT_APP_API_URL=http://localhost:3001/api
   ```

2. Update `TTSService.js` to use environment variables:
   ```javascript
   const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://your-api-url.com';
   ```

## 🎨 Styling

The application uses the same beautiful design as the original:
- Gradient backgrounds
- Floating hearts animation
- Pink/purple color scheme
- Responsive design
- Smooth animations

## 🔍 Error Handling

The React version includes improved error handling:

- **Network errors** - Clear messages for connection issues
- **API errors** - Specific error messages from the server
- **CORS errors** - Alternative API call methods
- **Timeout errors** - 30-second timeout with retry logic
- **Loading states** - Visual feedback during requests

## 🚀 Deployment

The React app is automatically built and deployed using the main deployment scripts:

```powershell
# From project root
.\deploy.ps1
```

This will:
1. Build the React application
2. Update API URLs
3. Upload to S3
4. Deploy the complete application

## 🧪 Testing

### Manual Testing
1. Start the development server
2. Open browser developer tools (F12)
3. Try generating audio with different texts
4. Check console for any errors

### API Testing
The service includes a connection test method:
```javascript
import TTSService from './services/TTSService';

// Test API connectivity
TTSService.testConnection().then(result => {
  console.log('API connection:', result);
});
```

## 🔧 Troubleshooting

### Common Issues

1. **CORS Errors**
   - The service includes alternative API call methods
   - Check browser console for specific error messages

2. **Build Errors**
   - Ensure Node.js is installed
   - Run `npm install` to install dependencies
   - Check for syntax errors in React components

3. **API Connection Issues**
   - Verify the API URL in `TTSService.js`
   - Check if the Lambda function is deployed
   - Test API directly with curl or Postman

### Debug Mode
Enable debug logging by opening browser console. The service logs all API calls and responses.

## 📱 Mobile Support

The application is fully responsive and works on:
- Desktop browsers
- Mobile browsers
- Tablets
- Progressive Web App (PWA) ready

## 🎯 Performance

- **Code splitting** - Automatic code splitting with Create React App
- **Optimized builds** - Production builds are optimized and minified
- **Lazy loading** - Components load only when needed
- **Error boundaries** - Graceful error handling

---

**Happy Text-to-Speech! 🎤✨**

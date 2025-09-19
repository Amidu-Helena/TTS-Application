import axios from 'axios';

// API Configuration
const API_BASE_URL = 'https://4b5jz7mn34.execute-api.us-east-1.amazonaws.com/prod';

// Create axios instance with default configuration
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 seconds timeout
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging
apiClient.interceptors.request.use(
  (config) => {
    console.log('Making request to:', config.url);
    return config;
  },
  (error) => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => {
    console.log('Response received:', response.status);
    return response;
  },
  (error) => {
    console.error('Response error:', error);
    
    if (error.code === 'ECONNABORTED') {
      throw new Error('Request timeout - please try again');
    }
    
    if (error.response) {
      // Server responded with error status
      const status = error.response.status;
      const data = error.response.data;
      
      switch (status) {
        case 400:
          throw new Error(data.error || 'Invalid request');
        case 403:
          throw new Error('Access denied - CORS issue');
        case 404:
          throw new Error('API endpoint not found');
        case 500:
          throw new Error(data.error || 'Server error');
        default:
          throw new Error(`Server error (${status}): ${data.error || 'Unknown error'}`);
      }
    } else if (error.request) {
      // Network error
      throw new Error('Network error - please check your connection');
    } else {
      // Other error
      throw new Error(error.message || 'Unknown error occurred');
    }
  }
);

class TTSService {
  static async convertText(text, voice = 'Joanna') {
    try {
      console.log('Converting text:', { text: text.substring(0, 50) + '...', voice });
      
      const response = await apiClient.post('/convert', {
        text,
        voice
      });

      console.log('Conversion successful:', response.data);
      return response.data;
      
    } catch (error) {
      console.error('TTS Service Error:', error);
      
      // Try alternative approach if main API fails
      if (error.message.includes('CORS') || error.message.includes('Network')) {
        console.log('Trying alternative API call...');
        return await this.convertTextAlternative(text, voice);
      }
      
      throw error;
    }
  }

  // Alternative method using fetch with different configuration
  static async convertTextAlternative(text, voice = 'Joanna') {
    try {
      console.log('Trying alternative API call...');
      
      const response = await fetch(`${API_BASE_URL}/convert`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        mode: 'cors',
        credentials: 'omit',
        body: JSON.stringify({ text, voice })
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log('Alternative API call successful:', data);
      return data;
      
    } catch (error) {
      console.error('Alternative API call failed:', error);
      throw new Error(`API call failed: ${error.message}`);
    }
  }

  // Test API connectivity
  static async testConnection() {
    try {
      const response = await apiClient.options('/convert');
      console.log('API connection test successful');
      return true;
    } catch (error) {
      console.error('API connection test failed:', error);
      return false;
    }
  }
}

export default TTSService;

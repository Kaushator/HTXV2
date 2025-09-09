# WebSocket Ticker UI

Real-time cryptocurrency ticker interface using WebSocket connection to the backend.

## Features

- **Real-time Price Updates**: Live streaming of cryptocurrency prices via WebSocket
- **Multiple Symbol Support**: Track multiple cryptocurrencies simultaneously (BTC, ETH, etc.)
- **Configurable Update Interval**: Adjustable refresh rate from 200ms to 10000ms
- **Connection Management**: Easy connect/disconnect controls with status indicators
- **Error Handling**: Graceful handling of connection errors and data parsing issues
- **Responsive Design**: Mobile-friendly interface with card-based layout
- **Price Change Indicators**: Visual indicators for price movements (up/down)

## Components

### useWebSocket Hook (`src/hooks/useWebSocket.ts`)
- Custom React hook for WebSocket connection management
- Automatic reconnection with configurable attempts and intervals
- Status tracking (connecting, connected, disconnected, error)
- Message handling with JSON parsing
- Lifecycle callbacks for connection events

### TickerCard Component (`src/components/TickerCard.tsx`)
- Individual cryptocurrency price display card
- Real-time price updates with color-coded changes
- 24h statistics (high, low, volume, change percentage)
- Loading states and error handling
- Responsive design with hover effects

### WebSocketControls Component (`src/components/WebSocketControls.tsx`)
- Connection management interface
- Symbol addition/removal
- Settings panel for interval configuration
- Connection status display with statistics
- Clean UI with collapsible settings

## Usage

### Accessing the Ticker
Navigate to `/ticker` in the application to access the real-time ticker interface.

### Adding Symbols
1. Enter a cryptocurrency symbol (e.g., BTC, ETH, DOGE) in the input field
2. Press Enter or click the + button to add the symbol
3. Click on existing symbol badges to remove them

### Connecting to WebSocket
1. Ensure you have at least one symbol added
2. Click the "Connect" button to start receiving real-time data
3. The status indicator will show "Connected" when successful
4. Price cards will update automatically based on the configured interval

### Configuration
- **Update Interval**: Set between 200ms and 10000ms in the settings panel
- **Symbols**: Add/remove cryptocurrency symbols as needed
- **Reconnection**: Automatic reconnection on connection loss (up to 5 attempts)

## WebSocket Protocol

The interface connects to the backend WebSocket endpoint:
```
ws://localhost:8000/ws/ticker?symbols=BTC,ETH&interval_ms=1000
```

### Message Format
The backend sends messages in the following format:
```json
{
  "type": "ticker_batch",
  "data": {
    "BTC": {
      "symbol": "BTC",
      "price": 50000.00,
      "change_24h": 1500.00,
      "change_24h_percent": 3.1,
      "volume_24h": 1234567890,
      "high_24h": 51000.00,
      "low_24h": 48500.00,
      "timestamp": "2025-09-09T12:00:00Z",
      "source": "HTX"
    },
    "ETH": {
      // ... similar structure
    }
  }
}
```

### Error Handling
- Invalid symbols will return error objects in the data
- Connection errors trigger automatic reconnection
- JSON parsing errors are logged and ignored
- Network timeouts are handled gracefully

## Testing

Basic WebSocket functionality is tested in `src/__tests__/useWebSocket.test.ts`:
- WebSocket mock implementation
- Connection lifecycle events
- Message handling
- Error scenarios

To run tests:
```bash
npm run test
```

## Development Notes

### Environment-specific URLs
The WebSocket URL is automatically configured based on the environment:
- Development: `ws://localhost:8000`
- Production: Uses current host with WebSocket protocol

### Performance Considerations
- Minimum update interval of 200ms to prevent server overload
- Connection pooling handled by the browser
- Automatic cleanup on component unmount
- Efficient re-renders using React state management

### Browser Compatibility
- Modern browsers with WebSocket support
- Automatic fallback handling for connection issues
- Progressive enhancement approach

## Future Enhancements

- [ ] Historical price charts
- [ ] Price alerts and notifications
- [ ] Portfolio tracking integration
- [ ] Advanced technical indicators
- [ ] Export data functionality
- [ ] Multiple exchange support
- [ ] Dark/light theme toggle
- [ ] Mobile app-like PWA features

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Input } from '@/components/ui/input'

describe('Input', () => {
  it('renders with default attributes', () => {
    render(<Input placeholder="Enter text" />)
    
    const input = screen.getByPlaceholderText('Enter text')
    expect(input).toBeInTheDocument()
    // Input component doesn't set default type, browser handles it
    expect(input).toHaveAttribute('placeholder', 'Enter text')
  })

  it('renders with custom type', () => {
    render(<Input type="email" placeholder="Enter email" />)
    
    const input = screen.getByPlaceholderText('Enter email')
    expect(input).toHaveAttribute('type', 'email')
  })

  it('handles user input', async () => {
    const user = userEvent.setup()
    render(<Input placeholder="Type here" />)
    
    const input = screen.getByPlaceholderText('Type here')
    await user.type(input, 'Hello World')
    
    expect(input).toHaveValue('Hello World')
  })

  it('handles onChange events', async () => {
    const handleChange = vi.fn()
    const user = userEvent.setup()
    
    render(<Input onChange={handleChange} placeholder="Change test" />)
    
    const input = screen.getByPlaceholderText('Change test')
    await user.type(input, 'a')
    
    expect(handleChange).toHaveBeenCalled()
  })

  it('is disabled when disabled prop is true', () => {
    render(<Input disabled placeholder="Disabled input" />)
    
    const input = screen.getByPlaceholderText('Disabled input')
    expect(input).toBeDisabled()
    expect(input).toHaveClass('disabled:cursor-not-allowed', 'disabled:opacity-50')
  })

  it('accepts and displays default value', () => {
    render(<Input defaultValue="Default text" />)
    
    const input = screen.getByDisplayValue('Default text')
    expect(input).toBeInTheDocument()
  })

  it('accepts controlled value', () => {
    render(<Input value="Controlled value" onChange={() => {}} />)
    
    const input = screen.getByDisplayValue('Controlled value')
    expect(input).toBeInTheDocument()
  })

  it('forwards ref correctly', () => {
    const ref = vi.fn()
    
    render(<Input ref={ref} placeholder="Ref test" />)
    
    expect(ref).toHaveBeenCalled()
  })

  it('applies custom className', () => {
    render(<Input className="custom-input" placeholder="Custom class" />)
    
    const input = screen.getByPlaceholderText('Custom class')
    expect(input).toHaveClass('custom-input')
  })

  it('forwards other HTML attributes', () => {
    render(
      <Input 
        data-testid="test-input" 
        id="my-input" 
        aria-label="Test Input"
        placeholder="Attributes test"
      />
    )
    
    const input = screen.getByTestId('test-input')
    expect(input).toHaveAttribute('id', 'my-input')
    expect(input).toHaveAttribute('aria-label', 'Test Input')
  })

  it('has correct base classes', () => {
    render(<Input placeholder="Base classes" />)
    
    const input = screen.getByPlaceholderText('Base classes')
    expect(input).toHaveClass(
      'flex',
      'h-10',
      'w-full',
      'rounded-md',
      'border',
      'bg-background',
      'px-3',
      'py-2',
      'text-sm'
    )
  })

  it('supports different input types', () => {
    const types = ['text', 'email', 'password', 'number', 'tel', 'url']
    
    types.forEach((type) => {
      const { unmount } = render(<Input type={type as any} placeholder={`${type} input`} />)
      
      const input = screen.getByPlaceholderText(`${type} input`)
      expect(input).toHaveAttribute('type', type)
      
      unmount()
    })
  })

  it('handles focus and blur events', async () => {
    const handleFocus = vi.fn()
    const handleBlur = vi.fn()
    const user = userEvent.setup()
    
    render(<Input onFocus={handleFocus} onBlur={handleBlur} placeholder="Focus test" />)
    
    const input = screen.getByPlaceholderText('Focus test')
    
    await user.click(input)
    expect(handleFocus).toHaveBeenCalledTimes(1)
    
    await user.tab()
    expect(handleBlur).toHaveBeenCalledTimes(1)
  })
})

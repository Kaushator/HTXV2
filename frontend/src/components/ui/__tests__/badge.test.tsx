import { render, screen } from '@testing-library/react'
import { Badge } from '@/components/ui/badge'

describe('Badge', () => {
  it('renders with default variant', () => {
    render(<Badge>Default Badge</Badge>)
    
    const badge = screen.getByText('Default Badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveClass('bg-primary', 'text-primary-foreground')
  })

  it('renders with secondary variant', () => {
    render(<Badge variant="secondary">Secondary Badge</Badge>)
    
    const badge = screen.getByText('Secondary Badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveClass('bg-secondary', 'text-secondary-foreground')
  })

  it('renders with destructive variant', () => {
    render(<Badge variant="destructive">Error Badge</Badge>)
    
    const badge = screen.getByText('Error Badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveClass('bg-destructive', 'text-destructive-foreground')
  })

  it('renders with outline variant', () => {
    render(<Badge variant="outline">Outline Badge</Badge>)
    
    const badge = screen.getByText('Outline Badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveClass('text-foreground')
  })

  it('applies custom className', () => {
    render(<Badge className="custom-class">Custom Badge</Badge>)
    
    const badge = screen.getByText('Custom Badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveClass('custom-class')
  })

  it('forwards other HTML attributes', () => {
    render(<Badge data-testid="test-badge" id="my-badge">Test Badge</Badge>)
    
    const badge = screen.getByTestId('test-badge')
    expect(badge).toBeInTheDocument()
    expect(badge).toHaveAttribute('id', 'my-badge')
  })

  it('has correct base classes', () => {
    render(<Badge>Base Classes Badge</Badge>)
    
    const badge = screen.getByText('Base Classes Badge')
    expect(badge).toHaveClass(
      'inline-flex',
      'items-center', 
      'rounded-full',
      'border',
      'px-2.5',
      'py-0.5',
      'text-xs',
      'font-semibold'
    )
  })
})

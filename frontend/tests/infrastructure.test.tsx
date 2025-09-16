import React from 'react'
import { render, screen } from '@testing-library/react'
import { expect, test, describe } from 'vitest'

// Example component test
describe('Frontend Test Infrastructure', () => {
  test('test infrastructure is working', () => {
    const testElement = document.createElement('div')
    testElement.textContent = 'Hello HTXV2'
    document.body.appendChild(testElement)
    
    expect(document.body.textContent).toContain('Hello HTXV2')
  })
  
  test('react testing library is configured', () => {
    const { container } = render(
      <div data-testid="test-component">Test Component</div>
    )
    
    expect(screen.getByTestId('test-component')).toBeInTheDocument()
    expect(container.firstChild).toHaveTextContent('Test Component')
  })
})
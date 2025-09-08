import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'

function Hello() {
  return <h1>Hello HTX</h1>
}

describe('smoke', () => {
  it('renders a heading', () => {
    render(<Hello />)
    expect(screen.getByRole('heading', { name: /hello htx/i })).toBeInTheDocument()
  })
})


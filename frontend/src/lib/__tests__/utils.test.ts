import { cn } from '@/lib/utils'

describe('cn utility function', () => {
  it('merges class names correctly', () => {
    const result = cn('px-4', 'py-2', 'bg-blue-500')
    expect(result).toBe('px-4 py-2 bg-blue-500')
  })

  it('handles conditional classes', () => {
    const isActive = true
    const result = cn('base-class', isActive && 'active-class')
    expect(result).toBe('base-class active-class')
  })

  it('handles false conditional classes', () => {
    const isActive = false
    const result = cn('base-class', isActive && 'active-class')
    expect(result).toBe('base-class')
  })

  it('merges conflicting Tailwind classes correctly', () => {
    // tailwind-merge should keep the last conflicting class
    const result = cn('px-4', 'px-6')
    expect(result).toBe('px-6')
  })

  it('handles arrays of classes', () => {
    const result = cn(['px-4', 'py-2'], 'bg-blue-500')
    expect(result).toBe('px-4 py-2 bg-blue-500')
  })

  it('handles objects with conditional classes', () => {
    const result = cn({
      'base-class': true,
      'active-class': true,
      'hidden-class': false
    })
    expect(result).toBe('base-class active-class')
  })

  it('handles undefined and null values', () => {
    const result = cn('base-class', undefined, null, 'other-class')
    expect(result).toBe('base-class other-class')
  })

  it('handles empty input', () => {
    const result = cn()
    expect(result).toBe('')
  })

  it('handles complex mixed inputs', () => {
    const isActive = true
    const variant = 'primary'
    
    const result = cn(
      'base-class',
      {
        'active': isActive,
        'inactive': !isActive
      },
      variant === 'primary' && 'primary-class',
      ['extra-class-1', 'extra-class-2']
    )
    
    expect(result).toBe('base-class active primary-class extra-class-1 extra-class-2')
  })

  it('resolves Tailwind class conflicts in complex scenarios', () => {
    const result = cn(
      'p-4 bg-red-500',
      'p-6 bg-blue-500', // Should override previous padding and background
      'text-white'
    )
    
    expect(result).toBe('p-6 bg-blue-500 text-white')
  })
})

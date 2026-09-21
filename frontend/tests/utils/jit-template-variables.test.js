import { resolveJitTemplateVariables } from '../../src/utils/jit-template-variables'

const UPN = 'kbk@complea.dk'

describe('resolveJitTemplateVariables', () => {
  it('fills %cipptechnician% with the part of the signed-in UPN before @', () => {
    expect(resolveJitTemplateVariables('jit-%cipptechnician%', UPN)).toBe('jit-kbk')
  })

  it('fills %cipptechnicianupn% with the full UPN, case-insensitively', () => {
    expect(resolveJitTemplateVariables('Requested by %CIPPTECHNICIANUPN%', UPN)).toBe(
      'Requested by kbk@complea.dk'
    )
  })

  it('leaves unknown tokens as written so a typo stays visible', () => {
    expect(resolveJitTemplateVariables('%tenantname%-%cipptechnician%', UPN)).toBe(
      '%tenantname%-kbk'
    )
  })

  it('passes empty template text through unchanged so the caller guards still work', () => {
    expect(resolveJitTemplateVariables(undefined, UPN)).toBeUndefined()
    expect(resolveJitTemplateVariables('', UPN)).toBe('')
  })

  it('blanks the tokens when no UPN is known yet', () => {
    expect(resolveJitTemplateVariables('jit-%cipptechnician%', undefined)).toBe('jit-')
  })
})

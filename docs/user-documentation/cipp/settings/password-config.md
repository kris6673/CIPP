# Password Configuration

This page controls how CIPP generates passwords, covering new users, password resets, JIT admin accounts and anywhere else CIPP produces a credential. The setting applies across the whole instance rather than per tenant or per technician.

Choose a type using the toggle at the top of the card, configure the settings that appear for it, then select **Save**. Settings for the type you are not using are retained, so switching back and forth does not lose them.

## Password Type

| Type       | Description                                                                                                                                                                                           |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Classic    | Random characters drawn from the character classes you enable. Suited to systems that insist on specific character types. Sixteen characters or more is recommended for strong security.              |
| Passphrase | Random dictionary words joined by a separator. Easier to read out and retype, and typically stronger than a classic password of the same length. Five words or more is recommended for high security. |

## Classic Settings

| Setting                         | Description                                                                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Length                          | How many characters the password contains. Must be between 8 and 256. The default is 14.                                                                     |
| Uppercase (A-Z)                 | Includes uppercase letters.                                                                                                                                  |
| Lowercase (a-z)                 | Includes lowercase letters.                                                                                                                                  |
| Digits (0-9)                    | Includes numbers.                                                                                                                                            |
| Special Characters              | Includes symbols, drawn from the set below.                                                                                                                  |
| Special Characters (text field) | The symbols available to the generator, shown when the switch above is on. The default is `$%&*#`. Only `!@#$%^&*()-_=+/` are accepted, up to 32 characters. |

## Passphrase Settings

| Setting                  | Description                                                                                                                                  |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Words                    | How many words the passphrase contains. Must be between 3 and 10. The default is 4.                                                          |
| Separator                | The character placed between words. The default is a hyphen. Can be left empty, and accepts up to five characters from `!@#$%^&*()-_=+/`.    |
| Capitalize words         | Capitalises the first letter of each word, which supplies the uppercase character type.                                                      |
| Append number            | Adds a number to the end of the passphrase, which supplies the digit character type.                                                         |
| Append Special Character | Adds a symbol to the end of the passphrase, which supplies the special character type.                                                       |
| Special Characters       | The symbols available for the appended character, shown when **Append Special Character** is on. Same restrictions as for classic passwords. |

## Complexity Requirements

Microsoft 365 requires a password to contain at least three of the four character types: uppercase letters, lowercase letters, numbers and symbols. CIPP enforces this when you save, so a configuration that cannot meet it is rejected with an explanation rather than silently producing passwords Microsoft will refuse.

For classic passwords this means at least three of the four character class switches must be on.

For passphrases, the words themselves supply lowercase, so at least two of the following must also apply:

| Requirement | Supplied by                                                  |
| ----------- | ------------------------------------------------------------ |
| Uppercase   | Capitalize words                                             |
| Numbers     | Append number, or a separator containing a digit             |
| Symbols     | Append Special Character, or a separator containing a symbol |

{% hint style="info" %}
The separator counts towards complexity. A passphrase using the default hyphen separator already supplies the symbol type, so enabling **Capitalize words** alone is enough to satisfy the requirement.
{% endhint %}

{% hint style="warning" %}
Avoid setting the separator to a single space. Although the configuration will save, password generation rejects a whitespace-only separator, so credential creation will fail afterwards.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

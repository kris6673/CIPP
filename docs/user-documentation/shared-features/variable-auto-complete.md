# Variable Auto Complete

Text fields throughout CIPP support variables, which are placeholders replaced with real values when the setting, template, or alert is actually used. Rather than remembering the exact spelling of each one, type `%` in a supporting field and an autocomplete list appears. Continue typing to narrow it down, then pick the variable you want and CIPP inserts it complete with its surrounding `%` characters.

This ensures the variable name always matches exactly what CIPP expects.

## The Variable List

Each entry shows the variable as it will be inserted, a short description of what it resolves to, and a tag marking it as either **reserved** or **custom**.

| Type     | Description                                                                                                                                                                                                                                                                               |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reserved | Built into CIPP. These cover tenant details such as the tenant name, default domain, and tenant ID, along with partner and CIPP instance values. Some fields also offer system variables such as `%username%` and `%programfiles%`, for settings that are ultimately applied on a device. |
| Custom   | Variables you have defined yourself. Those set for All Tenants are available everywhere, and those set against a specific tenant apply only to that tenant.                                                                                                                               |

Typing after the `%` filters the list on both the variable name and its description, so searching for a term such as "domain" will surface the variables whose descriptions mention it even where the name does not.

{% hint style="info" %}
The list is drawn for the tenant currently selected, so a custom variable defined for one tenant will not appear while a different tenant is selected. Where a custom variable shares its name with one set for All Tenants, the tenant's own value takes precedence.
{% endhint %}

## Hotkey Support

Navigating the list is supported by the following hotkeys.

| Hotkey       | Action                                                          |
| ------------ | --------------------------------------------------------------- |
| Arrow Down   | Moves down the list, wrapping to the top from the last entry.   |
| Arrow Up     | Moves up the list, wrapping to the bottom from the first entry. |
| Tab or Enter | Accepts the selected variable in the list.                      |
| Escape       | Closes the autocomplete list.                                   |

You can also click an entry to insert it.

{% hint style="info" %}
The list closes on its own if what you type after the `%` stops looking like a variable name, for example when you type a space or punctuation. Type `%` again to bring it back.
{% endhint %}

{% include "../../../.gitbook/includes/feature-request.md" %}

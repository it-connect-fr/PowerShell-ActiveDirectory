# Get-ADUserLastLogon

Obtenir la date et l'heure de dernière connexion d'un utilisateur ou de tous les utilisateurs activés, via lecture de l'attribut lastLogon sur tous les DC.

# Paramètres

- **-Identity** : préciser le SamAccountName d'un compte utilisateur à cibler.

# Examples

```
    Get-ADUserLastLogon -Identity "admin.fb"
    Get-ADUserLastLogon
```

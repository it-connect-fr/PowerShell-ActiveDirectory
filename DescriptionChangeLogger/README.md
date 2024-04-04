# DescriptionChangeLogger

Créer un évènement dans l'Observateur d'évènements Windows lors de la détection de modification d'une description d'un objet "Utilisateur" (Active Directory)

# Détails

Se base pour cela sur une liste de descriptions (stockées sous forme GUID-hash) créée lors de la première exécution, puis mise à jour à chaque nouvelle exécution.
Le script va créer un fichier XML dans %TEMP% et y stockera les données récoltées lors de la dernière analyse en date. Ces informations seront comparées à l'analyse en cours lors de la prochaine exécution.

# Example

```
    .\DescriptionChangeLogger.ps1
```

# Ressources

- Lien vers l'article : [IT-Connect - Sécurité de l'Active Directory : les mots de passe dans la description des objets utilisateur](https://www.it-connect.fr/securite-active-directory-mots-de-passe-dans-la-description-des-objets-utilisateur/)
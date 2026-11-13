# Publier une version

Les versions sont publiées automatiquement par GitHub Actions
([.github/workflows/release.yml](../.github/workflows/release.yml)) avec le
[packager BigWigs](https://github.com/BigWigsMods/packager). Pousser un tag `v*`
construit le zip, le téléverse sur CurseForge et crée une release GitHub.

## Configuration (une seule fois)

1. **Créer le projet CurseForge** sur <https://authors.curseforge.com> :
   - Jeu : World of Warcraft, catégorie *Chat & Communication*
   - Nom : Tokebecicite
   - Résumé et description : copier depuis [CURSEFORGE.md](CURSEFORGE.md)
   - Logo : [logo.png](logo.png)
   - Licence : MIT
   - Source : lien vers le dépôt GitHub

   Attendre l'approbation du projet par CurseForge.

2. **Ajouter l'ID du projet dans le `.toc`.** L'ID est affiché dans la section
   *About Project* de la page CurseForge. Remplacer la ligne commentée dans
   `Tokebecicite.toc` par :

   ```
   ## X-Curse-Project-ID: 123456
   ```

3. **Créer un jeton API CurseForge** : <https://legacy.curseforge.com/account/api-tokens>,
   puis l'ajouter au dépôt GitHub dans
   *Settings → Secrets and variables → Actions → New repository secret* :
   - Nom : `CF_API_KEY`
   - Valeur : le jeton

## À chaque version

1. Ajouter une section en haut de [CHANGELOG.md](../CHANGELOG.md) (`## v1.1.0`, etc.).
   Le packager l'utilise comme notes de version.
2. Committer et pousser sur `main`.
3. Créer et pousser le tag :

   ```
   git tag v1.1.0
   git push origin v1.1.0
   ```

4. Suivre l'exécution dans l'onglet *Actions* du dépôt GitHub. Le fichier
   apparaît ensuite sur CurseForge (après une courte modération).

## Ce que fait le packager

- Remplace `@project-version@` dans le `.toc` par le nom du tag.
- Exclut les fichiers listés dans `.pkgmeta` (`tools/`, `docs/`, `CHANGELOG.md`)
  ainsi que les fichiers cachés (`.github`, `.gitignore`, `.pkgmeta`).
- Lit `## Interface: 16001` pour associer le fichier à **WoW: Forever**.

## Type de version

- Tag simple (`v1.1.0`) : version *Release*
- Tag contenant `alpha` ou `beta` (`v1.1.0-beta1`) : version *Alpha* ou *Beta*

## Mettre à jour l'interface

Quand WoW Forever change de version, mettre à jour `## Interface:` dans le `.toc`
(valeur obtenue en jeu avec `/dump select(4, GetBuildInfo())`), puis publier
une nouvelle version.

## Dépannage

- **Rien n'est envoyé sur CurseForge** : vérifier que `## X-Curse-Project-ID`
  est présent dans le `.toc` et que le secret `CF_API_KEY` existe.
- **Erreur de version de jeu** : vérifier la valeur `## Interface:`.
- Le zip est toujours disponible dans la release GitHub, même si l'envoi
  CurseForge échoue; on peut alors le téléverser à la main.

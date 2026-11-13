# Tokébakicitte ⚜

Add-on World of Warcraft (**WoW Forever**) qui fait parler ton personnage en bon québécois.
Au login, il lance une citation dans le chat de guilde; le reste du temps, tu en dis une quand tu veux, dans le chat de ton choix.

> *Tequila, Heineken, pas l'temps d'niaiser!*

## Fonctionnalités

- **117 citations** : expressions classiques (« Attache ta tuque avec d'la broche! »), mèmes québécois et quelques clins d'œil à Azeroth.
- **Citation au login** dans le chat de guilde, une seule fois par connexion (jamais après un `/reload`).
- **Citation sur demande** dans ton chat actif : dire, groupe, raid, guilde, chuchotement ou canal numéroté.
- **Cycle** : chaque citation est dite une fois avant que le cycle recommence, en ordre aléatoire ou dans l'ordre. La progression est conservée entre les sessions.
- **Favoris** : clique la fleur de lys d'une citation; tu peux limiter le login et/ou `/tokebec` à tes favoris.
- **Tes propres citations** : ajoute-les ou supprime-les directement en jeu.
- **Fenêtre d'options** sur fond de drapeau du Québec, avec recherche et filtres.
- **Bouton sur la minicarte** (déplaçable) et entrée dans le menu des add-ons.
- **Anti-spam** : 5 secondes minimum entre deux envois.

## Installation

**Avec l'application CurseForge** : cherche *Tokébakicitte* et installe-le pour WoW Forever.

**À la main** : télécharge le zip et extrais le dossier `Tokebakicitte` dans :

```
World of Warcraft\_forever_\Interface\AddOns\
```

Redémarre ensuite le jeu (un `/reload` ne suffit pas pour un nouvel add-on).

## Utilisation

| Commande | Effet |
|---|---|
| `/tokebec`, `/tokebak` ou `/qc` | Dit une citation dans ton chat actif |
| `/tokebec options` | Ouvre la fenêtre des favoris et options |
| `/tokebec guilde` | Dit une citation dans le chat de guilde |
| `/tokebec fav` | Ajoute/retire la dernière citation dite des favoris |
| `/tokebec auto` | Active/désactive la citation au login |
| `/tokebec minimap` | Affiche/cache le bouton de la minicarte |
| `/tokebec test` | Affiche une citation pour toi seulement |
| `/tokebec debug` | Active/désactive les messages de diagnostic |
| `/tokebec help` | Affiche la liste des commandes |

Le chat actif est celui de ta boîte de saisie : tape `/g`, `/p`, `/s` ou `/w Nom` une fois, puis `/tokebec` enverra là.
Astuce : mets `/tokebec` dans une macro pour avoir un bouton sur ta barre d'action.

**Bouton de la minicarte** : clic gauche pour la fenêtre d'options, clic droit pour dire une citation, glisser pour le déplacer.

### Fenêtre d'options

- Citation dans la guilde au login (on/off) et délai avant l'envoi (2 à 30 s)
- Favoris seulement : au login et/ou avec `/tokebec`
- Ordre aléatoire ou dans l'ordre de la liste
- Progression du cycle et bouton pour le recommencer
- Opacité du fond sombre (pour voir plus ou moins le drapeau)
- Affichage du bouton de la minicarte
- Liste des citations : recherche, filtre favoris, fleur de lys pour les favoris, bouton « Dire »
- Ajout de tes propres citations (en bleu pâle, supprimables avec **X**)

## Questions fréquentes

**Aucune citation au login?**
La citation part seulement à une vraie connexion (écran des personnages → Entrer dans le monde), pas après un `/reload`. Vérifie aussi que l'option est active (`/tokebec auto`) et que ton personnage est dans une guilde. Pour voir ce qui se passe : `/tokebec debug`, puis reconnecte-toi.

**« Doucement! Attends encore X s. »**
C'est l'anti-spam : 5 secondes minimum entre deux citations.

**Les images ne s'affichent pas (carrés verts)?**
Redémarre complètement le jeu après une installation ou une mise à jour.

**Mes favoris et réglages?**
Ils sont sauvegardés par compte dans `WTF\Account\<compte>\SavedVariables\Tokebakicitte.lua`.

## Compatibilité

- WoW Forever (interface 16001)
- Aucune bibliothèque externe requise

## Développement

| Fichier | Rôle |
|---|---|
| `Tokebakicitte.toc` | Métadonnées et ordre de chargement |
| `Sayings.lua` | Liste des citations intégrées |
| `Tokebakicitte.lua` | Cycle, favoris, envoi des messages, commandes |
| `Options.lua` | Fenêtre d'options |
| `Minimap.lua` | Bouton de la minicarte |
| `Media/` | Textures (drapeau, fleur de lys, icône) |
| `tools/make_textures.py` | Génère les textures et le logo (`python tools/make_textures.py`, Pillow requis) |
| `docs/` | Logo et description pour CurseForge, guide de publication |

Pour tester en jeu, copie le dossier dans `_forever_\Interface\AddOns\`, puis active les erreurs Lua avec `/console scriptErrors 1`.

Pour publier une nouvelle version, voir [docs/RELEASING.md](docs/RELEASING.md).

## Licence

[MIT](LICENSE) © 2026 Taaral

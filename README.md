# Tokebecicite
Wow addons pour dire des citations random purement quebecoise

## Installation
Copie le dossier `Tokebecicite` dans `World of Warcraft\_forever_\Interface\AddOns\` (WoW Forever, interface 16001).

## Utilisation
- Au login, une citation est envoyée automatiquement dans le chat de guilde.
- `/tokebec` (ou `/qc`) : envoie une citation dans ton chat actif (dire, groupe, raid, guilde, chuchotement, canal...).
- `/tokebec options` : ouvre la fenêtre des favoris et options.
- `/tokebec guilde` : envoie une citation dans le chat de guilde.
- `/tokebec fav` : ajoute/retire la dernière citation dite des favoris.
- `/tokebec auto` : active/désactive la citation au login.
- `/tokebec minimap` : affiche/cache le bouton de la minicarte (clic gauche : options, clic droit : dire une citation, glisser : déplacer).
- `/tokebec test` : affiche une citation pour toi seulement.

Les citations tournent en cycle : chacune est dite une fois avant que le cycle recommence.

## Fenêtre d'options
- Citation au login (on/off) et délai avant l'envoi
- Favoris seulement, au login et/ou avec `/tokebec`
- Ordre aléatoire ou dans l'ordre de la liste
- Liste des citations avec recherche, filtre favoris, bouton « Dire » et case favori
- Ajout/suppression de tes propres citations

## Textures
Les textures (`Media/QuebecFlag.tga`, `Media/FleurDeLys.tga`) sont générées par `python tools/make_textures.py` (Pillow requis). Après avoir ajouté ou modifié une texture, redémarre complètement le jeu : un `/reload` ne charge pas les nouveaux fichiers.

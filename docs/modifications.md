# Plan des modifications

## Réalisé : Mode texte (`feature/text-mode` → mergé dans main, v2.2.0)

### Spec

Permet d'écrire du texte directement à l'écran depuis le mode draw.

**Workflow** :
1. En mode Draw, appuyer sur `Q` → entre en mode texte
2. Le curseur de saisie suit la souris **en permanence**
3. Frappe libre → les caractères s'affichent attachés à la souris,
   couleur = `m_colorIndex` actif au moment d'entrer en mode texte
4. **Molette** → modifie la taille de la police du texte courant
5. **Backspace** → retire le dernier caractère tapé
6. **Clic gauche** → "pose" le texte à la position actuelle de la souris,
   le texte devient permanent (intégré à `m_drawLines`),
   puis **on sort du mode texte**
7. **Esc** → annule le texte en cours (rien n'est posé) et sort du mode texte

Pour taper un nouveau texte ailleurs, ré-appuyer sur `Q`.

**Pendant la saisie** : tous les autres raccourcis (0-9, e, c, m, t, etc.)
sont désactivés pour ne pas interférer avec la frappe. La table
d'accélérateurs est court-circuitée tant que `m_bTextMode == true`.

**Police** : Segoe UI, taille initiale = `m_currentPenWidth * 4`.

### Implémentation

**`MainWindow.h`** :
- Ajouter `LineType::Text` à l'enum (ligne 46-53)
- Ajouter membres dans `DrawLine` :
  - `std::wstring text`
  - `int fontSize`
- Ajouter membres dans `CMainWindow` :
  - `bool m_bTextMode = false`

**`MainWindow.cpp`** :
- Nouveau handler `WM_CHAR` :
  - Si `m_bTextMode`, append au `text` de la dernière `DrawLine` et
    `InvalidateRect` pour repaint
- Modifier `WM_KEYDOWN` (ou via accélérateur) pour traiter `Backspace` en
  mode texte : retire le dernier caractère au lieu de retirer la dernière
  ligne (`ID_CMD_UNDOLINE` actuel)
- `WM_MOUSEMOVE` : si `m_bTextMode`, mettre à jour `lineStartPoint` de la
  ligne en cours à chaque déplacement (le texte suit en permanence)
- `WM_LBUTTONDOWN` : si `m_bTextMode`, valider le texte et sortir du mode
  (au lieu de démarrer un trait à main levée)
- `WM_MOUSEWHEEL` : si `m_bTextMode`, modifier `fontSize` au lieu de
  couleur/épaisseur
- `WM_PAINT` : nouveau `case LineType::Text` → utiliser
  `Gdiplus::Graphics::DrawString` avec `Gdiplus::Font(L"Segoe UI", fontSize)`

**`DemoHelper.cpp`** (boucle de message principale) :
- Skip `TranslateAccelerator` quand `m_bTextMode == true` pour que les
  caractères arrivent en `WM_CHAR`

**`DemoHelper.rc`** :
- Ajouter accélérateur `"q", ID_CMD_TEXTMODE, ASCII, NOINVERT`

**`resource.h`** :
- Ajouter `#define ID_CMD_TEXTMODE …` (prochain ID libre)

**`Commands.cpp`** :
- Ajouter case `ID_CMD_TEXTMODE` :
  - Si pas déjà en mode texte : push une nouvelle `DrawLine` vide de
    type `Text`, set `m_bTextMode = true`, init `fontSize`
  - Gérer `ID_CMD_QUITMODE` (Esc) pour annuler le texte en cours
    avant de sortir du mode draw

### Tests manuels (validés)

- [x] `Q` en mode draw entre en mode texte
- [x] Tape "Hello" → s'affiche, suit la souris
- [x] Backspace retire les caractères
- [x] Molette change la taille
- [x] Clic pose le texte et sort du mode texte
- [x] Re-appuyer sur `Q` permet de taper un nouveau texte ailleurs
- [x] Esc annule, le texte courant disparaît, mode texte off
- [x] Pendant frappe, taper "extra" ne déclenche pas clear/marker
- [x] Couleur du texte = couleur active au moment du `Q`
- [x] Le texte posé persiste lors du undo (Backspace en mode draw classique)

### Notes d'implémentation

- Raccourci final : `Q` (au lieu de `I` initialement prévu — plus accessible
  près de la zone Ctrl+Shift).
- Skip de `TranslateAccelerator` quand `m_bTextMode == true` via le getter
  public `CMainWindow::IsInTextMode()` (sinon `Q`, `Backspace`, etc. sont
  capturés par la table d'accélérateurs avant `WM_CHAR`).
- `m_bTextMode` est remis à `false` dans `EndPresentationMode()` pour
  garantir un état propre à chaque sortie du mode draw.

## Idées futures

(à remplir au fur et à mesure)

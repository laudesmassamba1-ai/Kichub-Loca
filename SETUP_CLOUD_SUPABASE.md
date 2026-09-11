# Configuration Supabase cloud partagée

## 1) Créer le projet Supabase

- Aller sur https://supabase.com
- Créer un nouveau projet cloud (unique, partagé par tous les supports)
- Copier l'URL du projet et la clé anon publique

> Tous les supports (Android, iOS, Web) pointent vers **la même** URL du projet.

## 2) Variables d'environnement

Créer un fichier `.env` à la racine du projet :

```bash
SUPABASE_URL=https://<votre-projet>.supabase.co
SUPABASE_ANON_KEY=<votre-cle-publique>
```

Configurer le shell :

```bash
export SUPABASE_URL="https://<votre-projet>.supabase.co"
export SUPABASE_ANON_KEY="<votre-cle-publique>"
```

## 3) Import du schéma

Dans le SQL editor Supabase, exécuter le contenu de :

- `supabase/cloud_schema.sql`

Cela crée les tables partagées, les requêtes RPC (`commerces_proches`, `get_profile_summary`) et les policies RLS pour **tous** les utilisateurs.

## 4) Lancer l'application par support

Mêmes variables pour chaque support — la base est la même :

**Web**
```bash
flutter run --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -d chrome --web-port 3000
```

**Android (émulateur ou appareil)**
```bash
flutter run --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -d android
```

**iOS (sur macOS)**
```bash
flutter run --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -d ios
```

## 5) Sécurité

- La clé **anon** est publique, destinée au front. Combinée aux policies RLS, elle ne permet que les actions autorisées.
- La clé **service_role** (back-office) ne doit **jamais** être exposée côté client — ni dans l'app, ni sur le web.
- Les policies RLS du schéma :
  - profils : lus par tout utilisateur authentifié, modifiés uniquement par leur propriétaire
  - commerces : lus par tout utilisateur authentifié, modifiés par leur créateur
  - visites : lues par tout utilisateur authentifié, modifiées par l'agent concerné

## 6) Stockage des photos

Le bucket `commerce-photos` doit être créé dans Supabase Storage (visible publiquement pour l'affichage sur la carte et les fiches).
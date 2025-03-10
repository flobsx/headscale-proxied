#!/bin/bash

# Fonction pour vérifier si une chaîne est une clé YAML valide
is_valid_yaml_key() {
  local key="$1"
  # Vérifie que la clé ne contient pas d'espaces et commence par une lettre
  if [[ "$key" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# Demande les informations de l'utilisateur
read -p "👤 Entrez le login de l'utilisateur: " login

# Vérifie que le login est une clé YAML valide
while ! is_valid_yaml_key "$login"; do
  echo "❌ Le login n'est pas une clé YAML valide. Il doit commencer par une lettre et ne contenir que des lettres, chiffres, tirets ou underscores."
  read -p "👤 Entrez un login valide: " login
done

read -p "📧 Entrez l'email de l'utilisateur: " email
read -p "🏷️ Entrez le nom de l'utilisateur (appuyez sur Entrée pour utiliser le login): " nom

# Utilise le login comme nom si le champ est laissé vide
if [ -z "$nom" ]; then
  nom="$login"
fi

read -s -p "🔒 Entrez le mot de passe de l'utilisateur (laissez vide pour générer un mot de passe aléatoire): " password
echo # Pour passer à la ligne après la saisie du mot de passe

# Si un mot de passe est saisi, demande une confirmation
if [ -n "$password" ]; then
  read -s -p "🔒 Confirmez le mot de passe: " password_confirm
  echo # Pour passer à la ligne après la saisie du mot de passe

  while [ "$password" != "$password_confirm" ]; do
    echo "❌ Les mots de passe ne correspondent pas. Veuillez réessayer."
    read -s -p "🔒 Entrez le mot de passe de l'utilisateur: " password
    echo # Pour passer à la ligne après la saisie du mot de passe
    read -s -p "🔒 Confirmez le mot de passe: " password_confirm
    echo # Pour passer à la ligne après la saisie du mot de passe
  done
fi

# Génère un mot de passe aléatoire si aucun n'est fourni
if [ -z "$password" ]; then
  password=$(openssl rand -base64 20)
  echo -e "🔑 Mot de passe aléatoire généré et copié dans le presse-papiers."
  # Copie le mot de passe dans le presse-papiers
  if [ -x "$(command -v pbcopy)" ]; then
    echo "$password" | pbcopy
  elif [ -x "$(command -v xclip)" ]; then
    echo "$password" | xclip -selection clipboard
  elif [ -x "$(command -v xsel)" ]; then
    echo "$password" | xsel --clipboard
  fi
fi

# Demande si l'utilisateur veut afficher le mot de passe
read -p "Voulez-vous afficher le mot de passe généré ? (y/N): " show_password
if [ "$show_password" == "y" ]; then
  echo -e "🔑 Mot de passe généré: \e[33m$password\e[0m"
fi

# Génère le hash du mot de passe avec Authelia
hash_output=$(docker run authelia/authelia:latest authelia crypto hash generate argon2 --password "$password")
digest_value=$(echo "$hash_output" | grep "Digest:" | awk '{print $2}')

# Affiche le hash du mot de passe
echo "🔐 Hash du mot de passe généré : $digest_value"

# Supprime les '...' du fichier et ajoute le nouvel utilisateur
temp_file=$(mktemp)

# Copie le contenu du fichier en supprimant les '...'
sed '/^\.\.\./d' authelia/users_database.yml > "$temp_file"

# Ajoute le nouvel utilisateur avec la bonne indentation
cat >> "$temp_file" <<EOL

  $login:
    disabled: false
    displayname: "$nom"
    password: "$digest_value"
    email: $email
    groups:
      - admins
      - dev
EOL

# Remplace l'ancien fichier par le nouveau
mv "$temp_file" authelia/users_database.yml
chmod 644 authelia/users_database.yml

echo "✅ Utilisateur ajouté avec succès dans authelia/users_database.yml"

# Redémarre le conteneur Docker Authelia
echo "Redémarrage du conteneur Docker Authelia..."
docker compose restart authelia

echo "✅ Conteneur Docker Authelia redémarré avec succès."

#!/usr/bin/env python3
"""
Script de génération de données pour la formation OpenSearch.
Génère des produits, magasins et logs en français.
Usage: python3 generate-data.py --count 1000
"""

import argparse
import json
import random
import string
import uuid
from datetime import datetime, timedelta, timezone

# Essai d'import de faker, sinon fallback sur des données statiques
try:
    from faker import Faker
    faker = Faker("fr_FR")
    HAS_FAKER = True
except ImportError:
    HAS_FAKER = False
    faker = None


# ---------------------------------------------------------------------------
# Données de référence
# ---------------------------------------------------------------------------

CATEGORIES = {
    "Électronique": {
        "weight": 0.30,
        "sub_categories": [
            "Ordinateurs portables",
            "Smartphones",
            "Tablettes",
            "Casques",
            "Appareils photo",
        ],
        "brands": [
            "Samsung", "Apple", "Sony", "LG", "Philips",
            "Huawei", "Xiaomi", "Asus", "Dell", "HP",
        ],
        "price_range": (49.99, 2499.99),
        "tags_pool": [
            "technologie", "numérique", "connecté", "intelligent",
            "haute-performance", "sans-fil", "bluetooth", "wifi",
        ],
    },
    "Vêtements": {
        "weight": 0.20,
        "sub_categories": ["Chemises", "Pantalons", "Chaussures", "Vestes"],
        "brands": [
            "Zara", "H&M", "Lacoste", "Tommy Hilfiger",
            "Levi's", "Nike", "Adidas", "Uniqlo",
        ],
        "price_range": (9.99, 499.99),
        "tags_pool": [
            "mode", "tendance", "confort", "élégant", "casual",
            "sport", "été", "hiver",
        ],
    },
    "Maison & Jardin": {
        "weight": 0.15,
        "sub_categories": ["Meubles", "Cuisine", "Décoration"],
        "brands": [
            "IKEA", "Maisons du Monde", "Habitat", "Conforama",
            "Leroy Merlin", "Castorama",
        ],
        "price_range": (14.99, 1999.99),
        "tags_pool": [
            "intérieur", "déco", "pratique", "moderne", "design",
            "artisanal", "naturel", "écologique",
        ],
    },
    "Sports": {
        "weight": 0.10,
        "sub_categories": ["Course", "Cyclisme", "Natation"],
        "brands": [
            "Nike", "Adidas", "Decathlon", "Salomon",
            "The North Face", "Asics", "Mizuno",
        ],
        "price_range": (9.99, 799.99),
        "tags_pool": [
            "sport", "fitness", "outdoor", "performance",
            "endurance", "compétition", "loisir",
        ],
    },
    "Livres": {
        "weight": 0.10,
        "sub_categories": ["Fiction", "Non-Fiction", "Informatique", "BD"],
        "brands": [
            "Gallimard", "Flammarion", "Hachette", "Éditions Albin Michel",
            "Le Seuil", "Actes Sud", "O'Reilly",
        ],
        "price_range": (4.99, 89.99),
        "tags_pool": [
            "lecture", "culture", "savoir", "roman", "essai",
            "jeunesse", "classique", "bestseller",
        ],
    },
    "Alimentation": {
        "weight": 0.10,
        "sub_categories": ["Bio", "Snacks", "Boissons"],
        "brands": [
            "Danone", "Nestlé", "Mondelez", "Bjorg",
            "Léa Nature", "Biocoop", "Alter Eco",
        ],
        "price_range": (0.99, 59.99),
        "tags_pool": [
            "bio", "naturel", "sans-gluten", "vegan",
            "gourmand", "artisanal", "local", "équitable",
        ],
    },
    "Jouets": {
        "weight": 0.05,
        "sub_categories": ["Éducatif", "Jeux de société", "Plein air"],
        "brands": [
            "Lego", "Playmobil", "Hasbro", "Mattel",
            "Ravensburger", "Nathan", "Clementoni",
        ],
        "price_range": (4.99, 299.99),
        "tags_pool": [
            "enfant", "éducatif", "créatif", "amusant",
            "famille", "collectif", "dextérité",
        ],
    },
}

FRENCH_COLORS = [
    "Noir", "Blanc", "Gris", "Argent", "Or", "Rouge", "Bleu", "Vert",
    "Jaune", "Orange", "Violet", "Rose", "Beige", "Marron", "Turquoise",
    "Bordeaux", "Kaki", "Crème", "Corail", "Lavande",
]

FRENCH_CITIES = [
    ("Paris", (48.85, 2.35)),
    ("Lyon", (45.75, 4.85)),
    ("Marseille", (43.30, 5.37)),
    ("Toulouse", (43.60, 1.44)),
    ("Bordeaux", (44.84, -0.58)),
    ("Lille", (50.63, 3.07)),
    ("Strasbourg", (48.57, 7.75)),
    ("Nantes", (47.22, -1.55)),
    ("Nice", (43.71, 7.26)),
    ("Rennes", (48.11, -1.68)),
    ("Montpellier", (43.61, 3.88)),
    ("Grenoble", (45.19, 5.72)),
]

STORE_TYPES = ["flagship", "standard", "outlet", "click-and-collect"]

SERVICES = [
    "product-service", "cart-service", "payment-service",
    "user-service", "search-service", "recommendation-service",
    "inventory-service", "notification-service", "api-gateway",
]

LOG_MESSAGES = {
    "INFO": [
        "Requête traitée avec succès",
        "Utilisateur connecté",
        "Commande créée",
        "Paiement validé",
        "Produit ajouté au panier",
        "Stock mis à jour",
        "Email de confirmation envoyé",
        "Session démarrée",
        "Données synchronisées",
        "Cache actualisé",
        "Recherche effectuée",
        "Recommandations générées",
    ],
    "WARN": [
        "Tentative de connexion suspecte",
        "Temps de réponse élevé",
        "Stock faible pour le produit",
        "Timeout de connexion à la base de données",
        "Taux d'erreur en hausse",
        "Quota API presque atteint",
        "Certificat SSL bientôt expiré",
    ],
    "ERROR": [
        "Erreur de connexion à la base de données",
        "Paiement refusé",
        "Service indisponible",
        "Timeout de la requête",
        "Données invalides reçues",
        "Erreur d'authentification",
    ],
    "DEBUG": [
        "Démarrage du traitement de la requête",
        "Paramètres reçus",
        "Résultat du cache",
        "Appel SQL exécuté",
    ],
    "FATAL": [
        "Crash de l'application",
        "Perte de connexion critique",
        "Corruption de données détectée",
    ],
}

# ---------------------------------------------------------------------------
# Utilitaires
# ---------------------------------------------------------------------------

def random_date(days_back: int = 365) -> datetime:
    """Retourne une datetime aléatoire dans les `days_back` derniers jours."""
    now = datetime.now(timezone.utc)
    delta = timedelta(seconds=random.randint(0, days_back * 86400))
    return now - delta


def fmt_iso(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def weighted_choice(categories: dict) -> str:
    keys = list(categories.keys())
    weights = [categories[k]["weight"] for k in keys]
    return random.choices(keys, weights=weights, k=1)[0]


def random_trace_id() -> str:
    return "".join(random.choices(string.hexdigits[:16], k=32))


def random_user_id() -> str:
    return f"usr-{uuid.uuid4().hex[:12]}"


# ---------------------------------------------------------------------------
# Générateurs de contenu textuel en français (fallback sans faker)
# ---------------------------------------------------------------------------

PRODUCT_ADJECTIVES = [
    "innovant", "premium", "exclusif", "performant", "ergonomique",
    "compact", "léger", "robuste", "polyvalent", "élégant",
    "professionnel", "haut de gamme", "résistant", "pratique",
]

PRODUCT_NOUNS_BY_CAT = {
    "Électronique": [
        "ordinateur", "smartphone", "tablette", "casque", "appareil photo",
        "enceinte", "montre connectée", "clé USB", "disque dur", "écran",
    ],
    "Vêtements": [
        "chemise", "pantalon", "veste", "chaussure", "manteau",
        "pull", "robe", "short", "jean", "blouson",
    ],
    "Maison & Jardin": [
        "meuble", "lampe", "coussin", "tapis", "cadre",
        "vase", "pot de fleurs", "chaise", "table", "étagère",
    ],
    "Sports": [
        "chaussure de sport", "vélo", "maillot de bain", "sac de sport",
        "tapis de yoga", "haltère", "casque de vélo", "montre GPS",
    ],
    "Livres": [
        "roman", "guide pratique", "manuel", "album", "essai",
        "biographie", "bande dessinée", "atlas", "dictionnaire",
    ],
    "Alimentation": [
        "pack de jus", "barre céréalière", "café", "thé",
        "confiture", "huile d'olive", "miel", "granola",
    ],
    "Jouets": [
        "puzzle", "jeu de société", "figurine", "kit créatif",
        "voiture télécommandée", "set de construction", "peluche",
    ],
}

DESCRIPTION_TEMPLATES = [
    (
        "Ce {adj} {noun} est conçu pour répondre aux besoins des utilisateurs les plus exigeants. "
        "Il offre des performances exceptionnelles et une durabilité remarquable. "
        "Son design moderne s'intègre parfaitement dans votre quotidien. "
        "Profitez d'une expérience utilisateur incomparable avec ce produit de choix."
    ),
    (
        "Découvrez ce {adj} {noun} qui allie esthétique et fonctionnalité. "
        "Fabriqué avec des matériaux de haute qualité, il vous accompagnera longtemps. "
        "Sa conception ergonomique garantit un confort optimal lors de chaque utilisation. "
        "Un incontournable pour tous ceux qui recherchent le meilleur."
    ),
    (
        "Le {noun} {adj} est le choix idéal pour ceux qui ne font pas de compromis sur la qualité. "
        "Équipé des dernières technologies, il vous offre des performances sans égal. "
        "Léger et pratique, il s'emporte partout avec facilité. "
        "Faites le choix de l'excellence avec ce produit exceptionnel."
    ),
    (
        "Optez pour ce {noun} {adj} et transformez votre expérience quotidienne. "
        "Chaque détail a été pensé pour vous offrir le meilleur confort. "
        "Sa qualité de fabrication irréprochable en fait un produit durable. "
        "Un excellent rapport qualité-prix qui saura vous convaincre."
    ),
]

SELLER_PREFIXES = [
    "BoutiqueExpress", "ShopFrance", "MegaStore", "EliteShop",
    "ProVente", "TopMarket", "DirectShop", "FlashVente",
    "PremiumShop", "VenteRapide",
]

STREET_TYPES = ["rue", "avenue", "boulevard", "place", "impasse", "allée"]
STREET_NAMES = [
    "de la République", "Victor Hugo", "Jean Jaurès", "du Commerce",
    "de la Paix", "des Lilas", "Gambetta", "Foch", "de Gaulle",
    "des Fleurs", "Lafayette", "Voltaire", "Zola", "du Marché",
    "de la Liberté", "de la Gare", "du Moulin", "des Écoles",
]


def fake_first_name() -> str:
    first_names = [
        "Sophie", "Emma", "Léa", "Manon", "Chloé",
        "Lucas", "Hugo", "Théo", "Tom", "Louis",
        "Alice", "Camille", "Inès", "Julie", "Marie",
        "Nathan", "Maxime", "Antoine", "Alexandre", "Pierre",
    ]
    return random.choice(first_names)


def fake_last_name() -> str:
    last_names = [
        "Martin", "Bernard", "Dubois", "Thomas", "Robert",
        "Richard", "Petit", "Durand", "Leroy", "Moreau",
        "Simon", "Laurent", "Lefebvre", "Michel", "Garcia",
        "David", "Bertrand", "Roux", "Vincent", "Fournier",
    ]
    return random.choice(last_names)


def fake_company() -> str:
    prefixes = ["Tech", "Digi", "Euro", "Pro", "Mega", "Smart", "Easy", "Top"]
    suffixes = ["Solutions", "Commerce", "Distribution", "Boutique", "Shop", "Market"]
    return random.choice(prefixes) + random.choice(suffixes)


def make_product_name(category: str, sub_category: str, adj: str) -> str:
    nouns = PRODUCT_NOUNS_BY_CAT.get(category, ["produit"])
    noun = random.choice(nouns)
    # Capitalise first letter
    return f"{noun.capitalize()} {adj}"


def make_description(category: str, adj: str) -> str:
    nouns = PRODUCT_NOUNS_BY_CAT.get(category, ["produit"])
    noun = random.choice(nouns)
    template = random.choice(DESCRIPTION_TEMPLATES)
    return template.format(adj=adj, noun=noun)


def make_address(city: str) -> str:
    number = random.randint(1, 150)
    street_type = random.choice(STREET_TYPES)
    street_name = random.choice(STREET_NAMES)
    postal_code = random.randint(10000, 99999)
    return f"{number} {street_type} {street_name}, {postal_code} {city}"


def make_seller() -> str:
    prefix = random.choice(SELLER_PREFIXES)
    suffix = random.randint(10, 99)
    return f"{prefix}{suffix}"


# ---------------------------------------------------------------------------
# Génération des produits
# ---------------------------------------------------------------------------

def generate_product(product_id: int) -> dict:
    category_name = weighted_choice(CATEGORIES)
    cat_data = CATEGORIES[category_name]
    sub_category = random.choice(cat_data["sub_categories"])
    brand = random.choice(cat_data["brands"])
    adj = random.choice(PRODUCT_ADJECTIVES)

    # Nom et description
    if HAS_FAKER:
        name = f"{sub_category} {adj} {brand}"
        description = faker.paragraph(nb_sentences=random.randint(2, 4))
    else:
        name = make_product_name(category_name, sub_category, adj)
        description = make_description(category_name, adj)

    # Prix
    price_min, price_max = cat_data["price_range"]
    price = round(random.uniform(price_min, price_max), 2)
    # original_price >= price (remise possible)
    discount_factor = random.uniform(1.0, 1.5)
    original_price = round(price * discount_factor, 2)

    # Stock
    in_stock = random.random() > 0.20  # ~80% en stock
    stock_quantity = random.randint(1, 500) if in_stock else 0

    # Rating
    rating = round(random.uniform(1.0, 5.0), 1)
    reviews_count = random.randint(0, 5000)

    # Tags
    tags_pool = cat_data["tags_pool"]
    tags = random.sample(tags_pool, k=min(random.randint(2, 5), len(tags_pool)))

    # Dates
    created_dt = random_date(365)
    # updated_at est après created_at
    seconds_after = random.randint(0, int((datetime.now(timezone.utc) - created_dt).total_seconds()))
    updated_dt = created_dt + timedelta(seconds=seconds_after)

    # Vendeur
    if HAS_FAKER:
        seller = faker.company()
    else:
        seller = make_seller()

    # Poids et couleur
    weight_kg = round(random.uniform(0.05, 25.0), 2)
    color = random.choice(FRENCH_COLORS)

    return {
        "id": product_id,
        "name": name,
        "description": description,
        "category": category_name,
        "sub_category": sub_category,
        "brand": brand,
        "price": price,
        "original_price": original_price,
        "currency": "EUR",
        "in_stock": in_stock,
        "stock_quantity": stock_quantity,
        "rating": rating,
        "reviews_count": reviews_count,
        "tags": tags,
        "created_at": fmt_iso(created_dt),
        "updated_at": fmt_iso(updated_dt),
        "seller": seller,
        "weight_kg": weight_kg,
        "color": color,
    }


# ---------------------------------------------------------------------------
# Génération des magasins
# ---------------------------------------------------------------------------

def generate_stores(count: int = 50) -> list:
    stores = []
    store_names_base = [
        "Grand Magasin", "Espace", "Centre", "Galerie", "Boutique",
        "Marché", "Comptoir", "Point de vente", "Atelier", "Maison",
    ]
    cat_list = list(CATEGORIES.keys())

    for i in range(1, count + 1):
        city_name, (base_lat, base_lon) = random.choice(FRENCH_CITIES)
        # Petite variation autour du centre-ville
        lat = round(base_lat + random.uniform(-0.05, 0.05), 6)
        lon = round(base_lon + random.uniform(-0.05, 0.05), 6)

        if HAS_FAKER:
            name = f"{faker.company()} {city_name}"
            address = faker.address().replace("\n", ", ")
        else:
            base_name = random.choice(store_names_base)
            name = f"{base_name} {city_name} {i}"
            address = make_address(city_name)

        # Horaires : ouverture entre 8h-10h, fermeture entre 18h-21h
        open_h = random.randint(8, 10)
        close_h = random.randint(18, 21)
        opening_hours = f"{open_h:02d}:00-{close_h:02d}:00"

        # Catégories proposées dans le magasin
        num_cats = random.randint(1, len(cat_list))
        store_cats = random.sample(cat_list, k=num_cats)

        stores.append(
            {
                "id": i,
                "name": name,
                "city": city_name,
                "address": address,
                "location": {"lat": lat, "lon": lon},
                "type": random.choice(STORE_TYPES),
                "opening_hours": opening_hours,
                "categories": store_cats,
                "employee_count": random.randint(2, 250),
            }
        )
    return stores


# ---------------------------------------------------------------------------
# Génération des logs
# ---------------------------------------------------------------------------

LOG_LEVEL_WEIGHTS = {
    "INFO": 0.70,
    "WARN": 0.15,
    "ERROR": 0.10,
    "DEBUG": 0.03,
    "FATAL": 0.02,
}


def generate_log_entry() -> dict:
    level = random.choices(
        list(LOG_LEVEL_WEIGHTS.keys()),
        weights=list(LOG_LEVEL_WEIGHTS.values()),
        k=1,
    )[0]

    service = random.choice(SERVICES)
    message = random.choice(LOG_MESSAGES[level])
    trace_id = random_trace_id()
    timestamp = fmt_iso(random_date(30))  # logs sur les 30 derniers jours

    entry: dict = {
        "timestamp": timestamp,
        "level": level,
        "service": service,
        "message": message,
        "trace_id": trace_id,
    }

    # Champs optionnels selon le niveau
    if level in ("INFO", "WARN", "ERROR", "FATAL"):
        entry["http_status"] = random.choice(
            [200, 200, 200, 201, 204, 400, 401, 403, 404, 429, 500, 502, 503]
        )
        entry["response_time_ms"] = random.randint(10, 5000)

    if random.random() > 0.3:
        entry["user_id"] = random_user_id()

    return entry


# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Génère des données de formation pour OpenSearch"
    )
    parser.add_argument(
        "--count",
        type=int,
        default=1000,
        help="Nombre de produits à générer (défaut: 1000)",
    )
    args = parser.parse_args()

    print(f"Génération de {args.count} produits...")

    # --- Produits ---
    products = [generate_product(i + 1) for i in range(args.count)]

    with open("products.json", "w", encoding="utf-8") as f:
        json.dump(products, f, ensure_ascii=False, indent=2)
    print(f"  products.json écrit ({len(products)} produits)")

    # Bulk NDJSON pour OpenSearch
    with open("products-bulk.ndjson", "w", encoding="utf-8") as f:
        for product in products:
            action = {"index": {"_index": "products", "_id": str(product["id"])}}
            f.write(json.dumps(action, ensure_ascii=False) + "\n")
            f.write(json.dumps(product, ensure_ascii=False) + "\n")
    print(f"  products-bulk.ndjson écrit ({len(products)} documents)")

    # --- Magasins ---
    stores = generate_stores(50)
    with open("stores.json", "w", encoding="utf-8") as f:
        json.dump(stores, f, ensure_ascii=False, indent=2)
    print(f"  stores.json écrit ({len(stores)} magasins)")

    # --- Logs ---
    logs = [generate_log_entry() for _ in range(500)]
    with open("logs-sample.json", "w", encoding="utf-8") as f:
        json.dump(logs, f, ensure_ascii=False, indent=2)
    print(f"  logs-sample.json écrit ({len(logs)} entrées de log)")

    print("\nGénération terminée avec succès !")
    if not HAS_FAKER:
        print("(Note: faker non disponible — données générées avec le fallback intégré)")


if __name__ == "__main__":
    main()

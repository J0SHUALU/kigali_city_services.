const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const services = [
  { name: "Kimironko Café", category: "Cafés", address: "Kimironko, Kigali", phone: "+250 788 100 001", description: "Popular neighbourhood café offering fresh coffee, pastries, and light meals in a cosy setting.", latitude: -1.9355, longitude: 30.1034, rating: 4.3, reviewCount: 45, createdBy: "seed" },
  { name: "Green Bean Coffee", category: "Cafés", address: "KG 11 Ave, Kigali", phone: "+250 788 100 002", description: "Specialty coffee shop sourcing beans directly from Rwandan farmers.", latitude: -1.9441, longitude: 30.0619, rating: 4.0, reviewCount: 38, createdBy: "seed" },
  { name: "Umuganda Coffee", category: "Cafés", address: "Remera, Kigali", phone: "+250 788 100 003", description: "Community-focused café with great wifi and a calm work atmosphere.", latitude: -1.9500, longitude: 30.1100, rating: 4.4, reviewCount: 29, createdBy: "seed" },
  { name: "Rownda Brew", category: "Cafés", address: "Nyamirambo, Kigali", phone: "+250 788 100 004", description: "Laid-back café known for its cold brew and local snacks.", latitude: -1.9700, longitude: 30.0400, rating: 4.2, reviewCount: 22, createdBy: "seed" },
  { name: "King Faisal Hospital", category: "Hospitals", address: "KG 544 St, Kigali", phone: "+250 788 200 001", description: "One of the leading referral hospitals in Rwanda offering specialist care.", latitude: -1.9441, longitude: 30.0619, rating: 4.5, reviewCount: 120, createdBy: "seed" },
  { name: "Pharmacie Centrale", category: "Pharmacies", address: "Avenue de la Paix, Kigali", phone: "+250 788 300 001", description: "Central pharmacy open 24 hours with a wide range of medications.", latitude: -1.9500, longitude: 30.0600, rating: 4.1, reviewCount: 60, createdBy: "seed" },
  { name: "Heaven Restaurant", category: "Restaurants", address: "KN 29 St, Kigali", phone: "+250 788 400 001", description: "Award-winning restaurant with panoramic views and Rwandan fusion cuisine.", latitude: -1.9441, longitude: 30.0619, rating: 4.7, reviewCount: 200, createdBy: "seed" },
  { name: "Nyandungu Eco Park", category: "Parks", address: "Nyandungu, Kigali", phone: "+250 788 500 001", description: "Urban wetland park perfect for morning walks and birdwatching.", latitude: -1.9300, longitude: 30.1200, rating: 4.6, reviewCount: 85, createdBy: "seed" },
  { name: "Kigali Public Library", category: "Libraries", address: "KG 7 Ave, Kigali", phone: "+250 788 600 001", description: "Modern public library with free wifi, study rooms, and a children's section.", latitude: -1.9441, longitude: 30.0619, rating: 4.4, reviewCount: 55, createdBy: "seed" },
  { name: "Kigali Genocide Memorial", category: "Attractions", address: "Gasabo, Kigali", phone: "+250 788 700 001", description: "A powerful memorial and museum honouring the victims of the 1994 genocide.", latitude: -1.9350, longitude: 30.0580, rating: 4.9, reviewCount: 310, createdBy: "seed" },
];

async function seed() {
  console.log("Seeding Firestore...");
  for (const s of services) {
    await db.collection("services").add({ ...s, timestamp: admin.firestore.Timestamp.now() });
    console.log(`   Added: ${s.name}`);
  }
  console.log("Done! All 10 services added.");
  process.exit(0);
}

seed().catch((e) => { console.error(e); process.exit(1); });

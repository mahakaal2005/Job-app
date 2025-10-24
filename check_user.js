const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
    projectId: 'look-gig-test'
});

const db = admin.firestore();
const email = 'atul.2428cse521@kiet.edu';

async function checkUser() {
    console.log(`\n🔍 Checking for user: ${email}\n`);

    // Check users_specific collection
    console.log('📁 Checking users_specific collection...');
    const usersSnapshot = await db.collection('users_specific')
        .where('email', '==', email)
        .get();

    if (!usersSnapshot.empty) {
        usersSnapshot.forEach(doc => {
            console.log('✅ Found in users_specific:');
            console.log('   Document ID:', doc.id);
            console.log('   Data:', JSON.stringify(doc.data(), null, 2));
        });
    } else {
        console.log('❌ Not found in users_specific');
    }

    // Check employers collection
    console.log('\n📁 Checking employers collection...');
    const employersSnapshot = await db.collection('employers')
        .where('email', '==', email)
        .get();

    if (!employersSnapshot.empty) {
        employersSnapshot.forEach(doc => {
            console.log('✅ Found in employers:');
            console.log('   Document ID:', doc.id);
            console.log('   Data:', JSON.stringify(doc.data(), null, 2));
        });
    } else {
        console.log('❌ Not found in employers');
    }

    // Check old employees collection
    console.log('\n📁 Checking employees collection (legacy)...');
    const employeesSnapshot = await db.collection('employees')
        .where('email', '==', email)
        .get();

    if (!employeesSnapshot.empty) {
        employeesSnapshot.forEach(doc => {
            console.log('✅ Found in employees:');
            console.log('   Document ID:', doc.id);
            console.log('   Data:', JSON.stringify(doc.data(), null, 2));
        });
    } else {
        console.log('❌ Not found in employees');
    }

    // Check old users collection
    console.log('\n📁 Checking users collection (legacy)...');
    const oldUsersSnapshot = await db.collection('users')
        .where('email', '==', email)
        .get();

    if (!oldUsersSnapshot.empty) {
        oldUsersSnapshot.forEach(doc => {
            console.log('✅ Found in users:');
            console.log('   Document ID:', doc.id);
            console.log('   Data:', JSON.stringify(doc.data(), null, 2));
        });
    } else {
        console.log('❌ Not found in users');
    }

    console.log('\n✅ Check complete!\n');
    process.exit(0);
}

checkUser().catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
});

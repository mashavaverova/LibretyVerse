import bcrypt from 'bcrypt';

const password = "defaultadmin"; // Replace with your desired password

bcrypt.hash(password, 10, (err, hash) => {
    if (err) {
        console.error('Error hashing password:', err);
    } else {
        console.log('Generated Hash:', hash);
    }
});

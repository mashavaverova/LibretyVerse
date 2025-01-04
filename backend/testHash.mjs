import bcrypt from 'bcrypt';

const storedHash = "$2b$10$B1qoptmzZEdZ1GmpEJar8.gjKtt.8l0VJnyIG.eOqNZmzT8sdWghK"; // Your stored hash
const password = "securepassword"; // The password you are trying to log in with

bcrypt.compare(password, storedHash, (err, result) => {
    if (err) {
        console.error("Error comparing passwords:", err);
    } else if (result) {
        console.log("Password matches!");
    } else {
        console.log("Password does not match.");
    }
});

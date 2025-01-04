import { hash } from 'bcrypt';
const hashedPassword = await hash("YourPlainTextPassword", 10);
console.log(hashedPassword);

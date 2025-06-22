import { getRequestURL, readBody } from 'h3';
import * as jose from 'jose';
import type { UserShape } from '../../utils/types';

export default defineEventHandler(async (event) => {
  const url = getRequestURL(event);
  const userShape = await readBody<UserShape>(event);

  const config = useRuntimeConfig();
  const token = await generateShapeTokenWithJose(userShape, config.authSecretPlaintext, url.origin, '1m'); // Set expiration time to 1 minute
  return token;
});

/**
 * Generates a JWT using the 'jose' library.
 *
 * @param shape - The shape definition to embed in the token.
 * @param secret - The raw (not Base64 encoded) secret signing key.
 * @param issuer - The issuer ('iss') claim for the token.
 * @param expiresIn - The token's expiration time (e.g., '2h', '7d').
 * @returns A promise that resolves to the signed JWT string.
 */
async function generateShapeTokenWithJose(
  shape: UserShape,
  secret: string,
  issuer: string,
  expiresIn: string = '1h'
): Promise<string> {
  // 1. The secret key must be encoded into a Uint8Array for jose
  const secretKey = new TextEncoder().encode(secret);

  // 2. Use the fluent SignJWT API to build and sign the token
  const jwt = await new jose.SignJWT({ shape }) // Set custom claims
    .setProtectedHeader({ alg: 'HS256' }) // Set the signing algorithm
    .setIssuedAt() // Set issued-at time to now
    .setIssuer(issuer) // Set the issuer
    .setExpirationTime(expiresIn) // Set the expiration time
    .sign(secretKey); // Sign with the key

  return jwt;
}

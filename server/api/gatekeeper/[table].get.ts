import { getRequestURL, getRouterParams, getQuery } from 'h3';
import * as jose from 'jose';

export default defineEventHandler(async (event) => {
  try {
    // Get the base URL (without query string)
    const url = getRequestURL(event);
    const baseUrl = url.origin + url.pathname;

    // Get the table parameter from the URL
    const { table } = getRouterParams(event);

    // Get the query parameters object
    const queryParams = getQuery(event);

    // Define the shape data for the token
    const userShape: Shape = {
      ...queryParams,
      table
    };

    const config = useRuntimeConfig();
    const token = await generateShapeTokenWithJose(userShape, config.authSecretPlaintext, baseUrl);

    return {
      status: 'success' as const,
      headers: {
        Authorization: `Bearer ${token}`
      },
      url: config.proxyShapeUrl,
      table
    };
  }
  catch (error) {
    console.error('Failed to generate authentication token:', error);
    event.node.res.statusCode = 400;
    return {
      status: 'error' as const,
      message: 'Failed to generate authentication token.'
    };
  }
});

// Define an interface for the shape data for strong typing
interface Shape {
  namespace?: string;
  table: string;
  where?: string;
  columns?: string;
}

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
  shape: Shape,
  secret: string,
  issuer: string,
  expiresIn: string = '1h'
): Promise<string> {
  // 1. The secret key must be encoded into a Uint8Array for jose
  const secretKey = new TextEncoder().encode(secret);

  // 2. Use the fluent SignJWT API to build and sign the token
  const jwt = await new jose.SignJWT({ shape: shape }) // Set custom claims
    .setProtectedHeader({ alg: 'HS256' }) // Set the signing algorithm
    .setIssuedAt() // Set issued-at time to now
    .setIssuer(issuer) // Set the issuer
    .setExpirationTime(expiresIn) // Set the expiration time
    .sign(secretKey); // Sign with the key

  return jwt;
}

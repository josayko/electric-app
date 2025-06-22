import { getRouterParams, getQuery } from 'h3';
import type { UserShape } from '../../utils/types';

export default defineEventHandler(async (event) => {
  try {
    // Get the table parameter from the URL
    const { table } = getRouterParams(event);

    // Get the query parameters object
    const queryParams = getQuery(event);

    // Define the shape data for the token
    const userShape: UserShape = {
      ...queryParams,
      table
    };

    const config = useRuntimeConfig();

    return {
      status: 'success' as const,
      userShape,
      url: config.proxyShapeUrl,
      table
    };
  }
  catch (error) {
    console.error('Failed to generate user shape:', error);
    event.node.res.statusCode = 400;
    return {
      status: 'error' as const,
      message: 'Failed to generate user shape'
    };
  }
});

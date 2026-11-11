// Runs one tiny database query so Supabase sees activity and doesn't pause the project.
// Vercel calls this once a day (see vercel.json). You can also open it in the browser to test.
import { supabase } from '#lib/supabase.js';

export async function GET() {
	const { error } = await supabase.rpc('username_available', { name: 'keepalive' });

	return new Response(JSON.stringify({ ok: !error, error: error?.message ?? null, time: new Date().toISOString() }), {
		status: error ? 500 : 200,
		headers: { 'content-type': 'application/json', 'cache-control': 'no-store' }
	});
}

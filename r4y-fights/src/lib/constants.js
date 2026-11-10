export const DISCIPLINES = ['boxing', 'kickboxing', 'muay_thai', 'mma', 'taekwondo'];
export const LEVELS = ['beginner', 'intermediate', 'advanced', 'pro'];

export const ACADEMY = {
	name: 'Tirana Sport Academy',
	tagline: 'House of Warriors',
	city: 'Tiranë, Albania',
	phone: '+355 69 76 82 202',
	phoneHref: 'tel:+355697682202',
	whatsapp: 'https://wa.me/355697682202',
	tiktok: 'https://www.tiktok.com/@r4yfromthefuture'
};

export function ageFrom(birthDate) {
	if (!birthDate) return null;
	const b = new Date(birthDate);
	const now = new Date();
	let age = now.getFullYear() - b.getFullYear();
	const m = now.getMonth() - b.getMonth();
	if (m < 0 || (m === 0 && now.getDate() < b.getDate())) age--;
	return age;
}

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        poetry: {
          primary: '#8B4513',
          secondary: '#D2691E',
          accent: '#FFD700',
          bg: '#FFF8E7'
        },
        wisdom: {
          primary: '#1E90FF',
          secondary: '#4169E1',
          accent: '#00CED1',
          bg: '#F0F8FF'
        },
        magic: {
          primary: '#9370DB',
          secondary: '#8A2BE2',
          accent: '#FF69B4',
          bg: '#F8F0FF'
        }
      },
      animation: {
        'float': 'float 3s ease-in-out infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'bounce-in': 'bounce-in 0.5s ease-out',
        'slide-up': 'slide-up 0.3s ease-out',
        'celebration': 'celebration 1s ease-out forwards',
        'heart-float': 'heart-float 1.8s ease-out forwards',
        'sparkle': 'sparkle 0.6s ease-out forwards',
        'breathe': 'breathe 3s ease-in-out infinite',
        'shake-screen': 'shake-screen 0.6s ease-out',
        'float-damage': 'float-damage 1.5s ease-out forwards',
        'boss-charge-pulse': 'boss-charge-pulse 1.2s ease-in-out infinite',
        'hp-drop': 'hp-drop 0.4s ease-out',
        'boss-shatter': 'boss-shatter 0.8s ease-out forwards',
        'finishing-pulse': 'finishing-pulse 0.8s ease-in-out infinite'
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' }
        },
        'pulse-glow': {
          '0%, 100%': { boxShadow: '0 0 5px rgba(255, 215, 0, 0.5)' },
          '50%': { boxShadow: '0 0 20px rgba(255, 215, 0, 0.8)' }
        },
        'bounce-in': {
          '0%': { transform: 'scale(0)', opacity: '0' },
          '50%': { transform: 'scale(1.2)' },
          '100%': { transform: 'scale(1)', opacity: '1' }
        },
        'slide-up': {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        },
        'celebration': {
          '0%': { transform: 'scale(0) rotate(0deg)', opacity: '0' },
          '50%': { transform: 'scale(1.2) rotate(10deg)', opacity: '1' },
          '100%': { transform: 'scale(1) rotate(0deg)', opacity: '1' }
        },
        'heart-float': {
          '0%': { transform: 'translateY(0) scale(0.5)', opacity: '1' },
          '50%': { transform: 'translateY(-60px) scale(1.2)', opacity: '1' },
          '100%': { transform: 'translateY(-120px) scale(0.8)', opacity: '0' }
        },
        'sparkle': {
          '0%': { transform: 'scale(0) rotate(0deg)', opacity: '1' },
          '100%': { transform: 'scale(1.5) rotate(180deg)', opacity: '0' }
        },
        'breathe': {
          '0%, 100%': { transform: 'scale(1)' },
          '50%': { transform: 'scale(1.06)' }
        },
        'shake-screen': {
          '0%, 100%': { transform: 'translateX(0) translateY(0)' },
          '10%': { transform: 'translateX(-6px) translateY(2px)' },
          '20%': { transform: 'translateX(5px) translateY(-3px)' },
          '30%': { transform: 'translateX(-4px) translateY(1px)' },
          '40%': { transform: 'translateX(3px) translateY(-2px)' },
          '50%': { transform: 'translateX(-2px) translateY(0)' },
          '60%': { transform: 'translateX(1px)' },
          '70%': { transform: 'translateX(-1px)' },
          '80%': { transform: 'translateX(0)' }
        },
        'float-damage': {
          '0%': { opacity: '1', transform: 'translateY(0) scale(1)' },
          '20%': { opacity: '1', transform: 'translateY(-15px) scale(1.3)' },
          '50%': { opacity: '0.8', transform: 'translateY(-40px) scale(1.1)' },
          '100%': { opacity: '0', transform: 'translateY(-70px) scale(0.8)' }
        },
        'boss-charge-pulse': {
          '0%, 100%': { boxShadow: '0 0 8px rgba(239, 68, 68, 0.5)', transform: 'scale(1)' },
          '25%': { boxShadow: '0 0 20px rgba(239, 68, 68, 0.8)', transform: 'scale(1.02)' },
          '50%': { boxShadow: '0 0 12px rgba(239, 68, 68, 0.6)', transform: 'scale(1)' },
          '75%': { boxShadow: '0 0 28px rgba(239, 68, 68, 0.9)', transform: 'scale(1.03)' }
        },
        'hp-drop': {
          '0%': { filter: 'brightness(1)' },
          '30%': { filter: 'brightness(2.5) saturate(0)' },
          '100%': { filter: 'brightness(1)' }
        },
        'boss-shatter': {
          '0%': { transform: 'scale(1) rotate(0deg)', opacity: '1' },
          '100%': { transform: 'scale(0) rotate(180deg)', opacity: '0' }
        },
        'finishing-pulse': {
          '0%, 100%': { transform: 'scale(1)', boxShadow: '0 0 10px rgba(234, 179, 8, 0.6)' },
          '50%': { transform: 'scale(1.05)', boxShadow: '0 0 30px rgba(234, 179, 8, 0.9)' }
        }
      }
    }
  },
  plugins: []
};

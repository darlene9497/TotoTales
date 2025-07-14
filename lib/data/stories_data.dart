import '../models/story.dart';

class StoriesData {
  static List<Story> stories = [
    Story(
      id: '1',
      title: 'The Little Lion\'s Big Heart',
      language: 'English',
      ageRange: '3-5',
      category: 'Animals',
      coverImageUrl: 'https://via.placeholder.com/300x400/FFB74D/FFFFFF?text=🦁',
      description: 'A heartwarming tale about a young lion who discovers the power of kindness.',
      dateAdded: DateTime.now().subtract(Duration(days: 1)),
      popularity: 95,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/FFB74D/FFFFFF?text=🦁🌅',
          text: 'In the golden savanna, there lived a little lion named Leo. Leo was different from other lions - he had a very big heart full of kindness.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/81C784/FFFFFF?text=🦁🐰',
          text: 'One day, Leo found a scared little rabbit hiding behind a rock. Instead of scaring the rabbit more, Leo smiled gently and asked, "Are you okay, little friend?"',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/64B5F6/FFFFFF?text=🦁🐰💙',
          text: 'The rabbit was amazed by Leo\'s kindness. From that day on, Leo became known as the lion with the biggest heart in all the savanna.',
        ),
      ],
    ),
    
    Story(
      id: '2',
      title: 'Simba na Rafiki Zake',
      language: 'Swahili',
      ageRange: '3-5',
      category: 'Friendship',
      coverImageUrl: 'https://via.placeholder.com/300x400/4CAF50/FFFFFF?text=🦁🌍',
      description: 'Hadithi ya urafiki kati ya simba mdogo na wanyamapori wengine.',
      dateAdded: DateTime.now().subtract(Duration(days: 2)),
      popularity: 87,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=🦁🌳',
          text: 'Simba mdogo aliishi msituni pamoja na mama yake. Alikuwa na shauku ya kupata marafiki wapya.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/FF9800/FFFFFF?text=🦁🐸🦋',
          text: 'Siku moja, Simba alikutana na chura na kipepeo. Wote walikuwa wapole na wakarimu.',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/E91E63/FFFFFF?text=🦁🐸🦋❤️',
          text: 'Tangu siku hiyo, Simba, chura na kipepeo wakawa marafiki wa karibu. Walipenda kucheza pamoja kila siku.',
        ),
      ],
    ),
    
    Story(
      id: '3',
      title: 'Le Petit Éléphant Courageux',
      language: 'French',
      ageRange: '6-8',
      category: 'Adventure',
      coverImageUrl: 'https://via.placeholder.com/300x400/9C27B0/FFFFFF?text=🐘',
      description: 'L\'histoire d\'un jeune éléphant qui découvre sa propre bravoure.',
      dateAdded: DateTime.now().subtract(Duration(days: 3)),
      popularity: 92,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/9C27B0/FFFFFF?text=🐘🌺',
          text: 'Il était une fois un petit éléphant nommé Élie qui vivait dans une belle forêt pleine de fleurs colorées.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/FF5722/FFFFFF?text=🐘🔥',
          text: 'Un jour, un feu a commencé dans la forêt. Élie avait peur, mais il savait qu\'il devait aider ses amis.',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/2196F3/FFFFFF?text=🐘💧',
          text: 'Élie a utilisé sa trompe pour aspirer de l\'eau de la rivière et éteindre le feu. Il était plus courageux qu\'il ne le pensait!',
        ),
      ],
    ),
    
    Story(
      id: '4',
      title: 'The Space Adventure',
      language: 'English',
      ageRange: '9-12',
      category: 'Science',
      coverImageUrl: 'https://via.placeholder.com/300x400/3F51B5/FFFFFF?text=🚀',
      description: 'Join Maya and her robot companion on an exciting journey through space.',
      dateAdded: DateTime.now().subtract(Duration(days: 4)),
      popularity: 98,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/3F51B5/FFFFFF?text=🚀🌌',
          text: 'Maya was a brilliant young astronaut who had always dreamed of exploring the cosmos. Today, she was finally launching her first mission to Mars.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/E91E63/FFFFFF?text=🤖🪐',
          text: 'Her robot companion, ZARA, helped her navigate through the asteroid belt. Together, they discovered something amazing on the red planet.',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=🌱🪐',
          text: 'They found signs of ancient life on Mars! Maya\'s discovery would change how humans understood the universe forever.',
        ),
      ],
    ),
    
    Story(
      id: '5',
      title: 'The Magic Garden',
      language: 'English',
      ageRange: '6-8',
      category: 'Fantasy',
      coverImageUrl: 'https://via.placeholder.com/300x400/8BC34A/FFFFFF?text=🌸',
      description: 'A magical tale about a garden where flowers can talk and grant wishes.',
      dateAdded: DateTime.now().subtract(Duration(days: 5)),
      popularity: 89,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/8BC34A/FFFFFF?text=🌸🌼',
          text: 'Emma discovered a secret garden behind her grandmother\'s house. The flowers there were unlike any she had ever seen.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/FF9800/FFFFFF?text=🌸✨',
          text: 'When Emma touched a golden sunflower, it began to speak! "Welcome, young one," it said with a warm, gentle voice.',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/E91E63/FFFFFF?text=🌸🌈',
          text: 'The flowers told Emma that the garden was magical and could grant one wish to those with pure hearts. Emma wished for her sick friend to get better.',
        ),
      ],
    ),
    
    Story(
      id: '6',
      title: 'Bustani ya Uchawi',
      language: 'Swahili',
      ageRange: '6-8',
      category: 'Fantasy',
      coverImageUrl: 'https://via.placeholder.com/300x400/673AB7/FFFFFF?text=🌺',
      description: 'Hadithi ya uchawi kuhusu bustani ambayo maua yanaweza kuongea.',
      dateAdded: DateTime.now().subtract(Duration(days: 6)),
      popularity: 85,
      pages: [
        StoryPage(
          pageNumber: 1,
          imageUrl: 'https://via.placeholder.com/400x300/673AB7/FFFFFF?text=🌺🌿',
          text: 'Amina aligundua bustani ya siri nyuma ya nyumba ya bibi yake. Maua huko yalikuwa ya kipekee.',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: 'https://via.placeholder.com/400x300/FF5722/FFFFFF?text=🌺💫',
          text: 'Amina alipogusa ua la dhahabu, lilianza kuongea! "Karibu, mtoto mdogo," lilisema kwa sauti laini.',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=🌺🌟',
          text: 'Maua yalimwambia Amina kuwa bustani ina uchawi na inaweza kutimiza ombi moja kwa wenye mioyo mikuu.',
        ),
      ],
    ),
  ];
}
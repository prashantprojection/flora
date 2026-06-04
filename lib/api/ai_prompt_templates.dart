class AiPromptTemplates {
  /// Builds the prompt for generating seasonal care tips.
  static String buildCareTips({
    required String plantName,
    String? species,
    required String plantingDate,
    required String location,
    String additionalDetails = '',
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) {
    String prompt =
        'You are Flo AI, an expert and friendly plant care assistant. Provide comprehensive, actionable care tips for a plant named "$plantName". '
        'Include advice on watering, fertilizing, pruning, and ambient light/temperature requirements.';
    if (species != null && species.isNotEmpty) {
      prompt += ' The species is $species.';
    }
    if (plantingDate.isNotEmpty) {
      prompt += ' It was planted on $plantingDate.';
    }
    if (location.isNotEmpty && location != 'Not Specified') {
      prompt +=
          ' The user is located in $location. Adjust all care recommendations for this climate, including monsoon season patterns if applicable.';
    }
    prompt +=
        ' Generate seasonal advice appropriate for the user\'s location ($location). '
        'If they are in the Southern Hemisphere, reverse the seasons. '
        'If the location is tropical, note wet/dry seasons instead.';
    if (plantStage != null && plantStage != 'mature') {
      prompt += ' Note that this plant is currently a $plantStage. Adjust care advice appropriately.';
    }
    if (hasGrowLight) {
      prompt += ' The plant is growing under a grow light.';
    }
    if (weatherLocation != null && weatherLocation.isNotEmpty) {
      prompt += ' The user\'s broader weather location/climate is $weatherLocation.';
    }
    if (additionalDetails.isNotEmpty) {
      prompt +=
          ' The user has a specific question or observation: "$additionalDetails". Address this directly in your tips.';
    }
    prompt +=
        ' Format the response as seasonal sections: Spring: [tip]\\nSummer: [tip]\\nAutumn: [tip]\\nWinter: [tip]\\n'
        '(or Wet Season/Dry Season if tropical). Do not include any introductory or concluding sentences.';
    return prompt;
  }

  /// Builds the prompt for disease diagnosis from an image.
  static String buildDiagnosis({String? additionalDetails}) {
    String prompt =
        'You are Flo AI, a friendly plant care expert. First, verify if the image actually contains a plant. '
        'If it does NOT contain a plant (e.g., it is a person, animal, or random object), identify what it is briefly but remind the user you are a plant expert. '
        'Respond exactly with this markdown structure and nothing else:\\n'
        '## Diagnosis\\n**This appears to be a [briefly identify the object], but I am Flo, a plant expert!**\\n## Severity\\n**None**\\n## Notes\\n**Please upload a clear image of a plant so I can help you diagnose it.**\\n\\n'
        'If it DOES contain a plant, analyze it and provide a detailed diagnosis.';
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      prompt +=
          ' The user has provided these additional details and specific query: "$additionalDetails". Focus your diagnosis and recommendations based on these details, but also provide a general health assessment.';
    } else {
      prompt +=
          ' Provide a concise health diagnosis, identify any visible issues, and offer specific, actionable recommendations for improvement. If the plant appears healthy, state that clearly.';
    }
    prompt += '''
Respond in Markdown format with the following structure (if it is a plant):
## Diagnosis
**[Your diagnosis here]**
## Severity
**[Low/Medium/High]**
## Treatment Steps
**[Numbered, concrete, step-by-step treatment plan]**
## Prevention
**[List of actionable precautions to prevent this issue in the future]**
''';
    return prompt;
  }

  /// Builds the prompt to validate a plant name.
  static String buildValidation(String name) {
    return 'Is "$name" a real plant? If yes, answer YES '
        'and suggest standard fertilizing frequency in days (integer). '
        'If no or unsure, answer NO. '
        'Format: YES|14 or NO. Do not add any other text.';
  }

  /// Builds the prompt to generate structured JSON care recommendations.
  static String buildRecommendations({
    required String plantName,
    String? species,
    required String location,
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) {
    final int month = DateTime.now().month;
    String locationClause = location.isNotEmpty
        ? 'User is in room "$location". '
        : '';
    if (weatherLocation != null && weatherLocation.isNotEmpty) {
      locationClause += 'The local climate is "$weatherLocation". Adjust watering frequency for this climate. ';
    }
    if (hasGrowLight) {
      locationClause += 'The plant is under a grow light (extended daylight). ';
    }
    if (plantStage != null && plantStage != 'mature') {
      locationClause += 'The plant is a $plantStage, so it may need gentler, more frequent watering. ';
    }
    locationClause += 'If outdoor location, suggest higher watering frequency (2-4 days). '
        'If indoor, suggest standard indoor frequency (7-14 days).';

    return '''
You are Flo AI, a friendly and expert plant care assistant. I am adding a new plant to my collection.
Name: "$plantName"
Species: "${species ?? 'Unknown'}"
Location: "$location"
Current Month: $month

First, evaluate if "$plantName" (contextualized by species if provided) is a legitimate plant name.
If INVALID, set "isValid" to false.

If VALID:
1. $locationClause
2. "wateringFrequency": Return an INTEGER representing days between watering.
3. "fertilizingFrequency": Return an INTEGER representing days between fertilizing.
4. "pruningFrequency": Return an INTEGER representing days between pruning.
5. "advice": Provide comprehensive care tips covering watering, fertilizing, pruning, and ambient light/temperature requirements. Format the tips by season:
   Spring: [Detailed Tip]\\nSummer: [Detailed Tip]\\nAutumn: [Detailed Tip]\\nWinter: [Detailed Tip]
6. "reasoning": Provide 2-3 concise bullet points explaining why these specific frequencies were chosen.

Respond STRICTLY in this JSON format:
{
  "isValid": boolean,
  "wateringFrequency": integer,
  "fertilizingFrequency": integer,
  "pruningFrequency": integer,
  "advice": "Spring: [Tip]\\nSummer: [Tip]\\nAutumn: [Tip]\\nWinter: [Tip]",
  "reasoning": "• Bullet 1\\n• Bullet 2"
}
Do not include markdown formatting like ```json. Just the raw JSON string.
''';
  }
}

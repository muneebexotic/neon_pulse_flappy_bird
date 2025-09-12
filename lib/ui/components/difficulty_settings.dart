import 'package:flutter/material.dart';
import '../../game/managers/settings_manager.dart';
import '../theme/neon_theme.dart';

/// Difficulty settings widget
class DifficultySettings extends StatefulWidget {
  final SettingsManager settingsManager;
  final Function(DifficultyLevel)? onDifficultyChanged;
  
  const DifficultySettings({
    super.key,
    required this.settingsManager,
    this.onDifficultyChanged,
  });

  @override
  State<DifficultySettings> createState() => _DifficultySettingsState();
}

class _DifficultySettingsState extends State<DifficultySettings> {
  late DifficultyLevel _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.settingsManager.difficultyLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.warningOrange.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.warningOrange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.warningOrange,
              shadows: NeonTheme.getNeonGlow(NeonTheme.warningOrange),
            ),
          ),
          const SizedBox(height: 20),

          // Difficulty Selection
          ...DifficultyLevel.values.map((difficulty) => _buildDifficultyOption(difficulty)),
          
          const SizedBox(height: 20),
          
          // Current Settings Preview
          _buildSettingsPreview(),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(DifficultyLevel difficulty) {
    final isSelected = difficulty == _selectedDifficulty;
    
    Color borderColor;
    Color accentColor;
    IconData icon;
    
    switch (difficulty) {
      case DifficultyLevel.easy:
        borderColor = NeonTheme.neonGreen;
        accentColor = NeonTheme.neonGreen;
        icon = Icons.sentiment_satisfied;
        break;
      case DifficultyLevel.normal:
        borderColor = NeonTheme.electricBlue;
        accentColor = NeonTheme.electricBlue;
        icon = Icons.sentiment_neutral;
        break;
      case DifficultyLevel.hard:
        borderColor = Colors.red;
        accentColor = Colors.red;
        icon = Icons.sentiment_very_dissatisfied;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectDifficulty(difficulty),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
              ? accentColor.withOpacity(0.15)
              : NeonTheme.charcoal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : borderColor.withOpacity(0.3),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          difficulty.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? accentColor : NeonTheme.white,
                            shadows: isSelected ? NeonTheme.getNeonGlow(accentColor) : null,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: accentColor,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      difficulty.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: NeonTheme.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Stats
                    Row(
                      children: [
                        _buildStatChip(
                          'Speed',
                          '${(difficulty.speedMultiplier * 100).toInt()}%',
                          accentColor,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          'Gap Size',
                          '${(difficulty.gapSizeMultiplier * 100).toInt()}%',
                          accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Radio indicator
              Radio<DifficultyLevel>(
                value: difficulty,
                groupValue: _selectedDifficulty,
                onChanged: (value) => _selectDifficulty(value!),
                activeColor: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: NeonTheme.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Settings Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: NeonTheme.electricBlue,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPreviewStat(
                  'Game Speed',
                  '${(_selectedDifficulty.speedMultiplier * 100).toInt()}%',
                  Icons.speed,
                  NeonTheme.hotPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewStat(
                  'Obstacle Gap',
                  '${(_selectedDifficulty.gapSizeMultiplier * 100).toInt()}%',
                  Icons.height,
                  NeonTheme.neonGreen,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Tip: You can change difficulty anytime from the pause menu during gameplay.',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: NeonTheme.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDifficulty(DifficultyLevel difficulty) async {
    setState(() => _selectedDifficulty = difficulty);
    await widget.settingsManager.setDifficultyLevel(difficulty);
    widget.onDifficultyChanged?.call(difficulty);
  }
}
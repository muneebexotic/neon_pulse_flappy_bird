import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../../models/bird_skin.dart';
import '../../models/achievement.dart';
import '../../game/managers/customization_manager.dart';

class CustomizationScreen extends StatefulWidget {
  final CustomizationManager customizationManager;

  const CustomizationScreen({
    Key? key,
    required this.customizationManager,
  }) : super(key: key);

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  BirdSkin? _previewSkin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _previewSkin = widget.customizationManager.selectedSkin;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CUSTOMIZATION',
          style: NeonTheme.headingStyle.copyWith(
            color: NeonTheme.primaryNeon,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: NeonTheme.primaryNeon,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeonTheme.primaryNeon,
          labelColor: NeonTheme.primaryNeon,
          unselectedLabelColor: NeonTheme.secondaryNeon.withOpacity(0.6),
          tabs: const [
            Tab(text: 'SKINS'),
            Tab(text: 'ACHIEVEMENTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkinsTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildSkinsTab() {
    return Column(
      children: [
        // Preview section
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: NeonTheme.primaryNeon, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.primaryNeon.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildSkinPreview(),
        ),
        
        // Skins grid
        Expanded(
          child: _buildSkinsGrid(),
        ),
        
        // Select button
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSelectButton(),
        ),
      ],
    );
  }

  Widget _buildSkinPreview() {
    if (_previewSkin == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bird preview (simplified representation)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _previewSkin!.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _previewSkin!.trailColor.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.flight,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skin info
          Text(
            _previewSkin!.name,
            style: NeonTheme.headingStyle.copyWith(
              color: _previewSkin!.primaryColor,
              fontSize: 20,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _previewSkin!.description,
            style: NeonTheme.bodyStyle.copyWith(
              color: NeonTheme.textColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!_previewSkin!.isUnlocked) ...[
            const SizedBox(height: 8),
            Text(
              'Unlock at ${_previewSkin!.unlockScore} points',
              style: NeonTheme.bodyStyle.copyWith(
                color: NeonTheme.warningNeon,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkinsGrid() {
    final skins = widget.customizationManager.availableSkins;
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];
        final isSelected = _previewSkin?.id == skin.id;
        final isCurrentlySelected = 
            widget.customizationManager.selectedSkin.id == skin.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _previewSkin = skin;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? NeonTheme.primaryNeon 
                    : NeonTheme.secondaryNeon.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: NeonTheme.cardColor.withOpacity(0.1),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: NeonTheme.primaryNeon.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skin preview
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: skin.isUnlocked 
                            ? skin.primaryColor 
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow: skin.isUnlocked ? [
                          BoxShadow(
                            color: skin.trailColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        Icons.flight,
                        color: skin.isUnlocked ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    
                    if (!skin.isUnlocked)
                      Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 16,
                      ),
                    
                    if (isCurrentlySelected)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: NeonTheme.successNeon,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Skin name
                Text(
                  skin.name,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: skin.isUnlocked 
                        ? NeonTheme.textColor 
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (!skin.isUnlocked)
                  Text(
                    '${skin.unlockScore} pts',
                    style: NeonTheme.bodyStyle.copyWith(
                      color: NeonTheme.warningNeon,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectButton() {
    final canSelect = _previewSkin?.isUnlocked ?? false;
    final isAlreadySelected = 
        _previewSkin?.id == widget.customizationManager.selectedSkin.id;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canSelect && !isAlreadySelected ? _selectSkin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSelect && !isAlreadySelected
              ? NeonTheme.primaryNeon
              : Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isAlreadySelected 
              ? 'SELECTED' 
              : canSelect 
                  ? 'SELECT SKIN' 
                  : 'LOCKED',
          style: NeonTheme.buttonStyle.copyWith(
            color: canSelect ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectSkin() async {
    if (_previewSkin == null) return;
    
    final success = await widget.customizationManager.selectSkin(_previewSkin!.id);
    
    if (success && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected ${_previewSkin!.name}',
            style: NeonTheme.bodyStyle,
          ),
          backgroundColor: NeonTheme.successNeon,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAchievementsTab() {
    final achievements = widget.customizationManager.achievements;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: achievement.isUnlocked 
              ? NeonTheme.successNeon 
              : NeonTheme.secondaryNeon.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: NeonTheme.cardColor.withOpacity(0.1),
        boxShadow: achievement.isUnlocked ? [
          BoxShadow(
            color: NeonTheme.successNeon.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Achievement icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? achievement.iconColor 
                  : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Achievement info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: achievement.isUnlocked 
                        ? NeonTheme.textColor 
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  achievement.description,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Progress bar
                LinearProgressIndicator(
                  value: achievement.progressPercentage,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    achievement.isUnlocked 
                        ? NeonTheme.successNeon 
                        : NeonTheme.primaryNeon,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${achievement.currentProgress}/${achievement.targetValue}',
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textColor.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                
                if (achievement.rewardSkinId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reward: Special skin',
                    style: NeonTheme.bodyStyle.copyWith(
                      color: NeonTheme.warningNeon,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Unlock status
          if (achievement.isUnlocked)
            Icon(
              Icons.check_circle,
              color: NeonTheme.successNeon,
              size: 24,
            ),
        ],
      ),
    );
  }
}
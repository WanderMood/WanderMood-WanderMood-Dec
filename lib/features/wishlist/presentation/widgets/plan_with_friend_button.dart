import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const _wmForest = Color(0xFF2A6049);
const _wmForestTint = Color(0xFFEBF3EE);

/// Secondary pill CTA on Explore place cards — opens the plan-with-friend sheet.
class PlanWithFriendButton extends StatelessWidget {
  const PlanWithFriendButton({
    super.key,
    required this.place,
    this.height = 36,
    this.onAddToMyDay,
    this.labelOverride,
  });

  final Place place;
  final double height;
  final VoidCallback? onAddToMyDay;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = height <= 42;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            openPlanWithFriend(
              context,
              PlanWithFriendArgs.fromPlace(
                place,
                onAddToMyDay: onAddToMyDay,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: compact ? 14 : 16,
                  color: _wmForest,
                ),
                SizedBox(width: compact ? 4 : 5),
                Flexible(
                  child: Text(
                    labelOverride ?? l10n.planMetVriendCta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _wmForest,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

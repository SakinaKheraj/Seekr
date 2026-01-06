import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_states.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const int totalSessions = 10;
    const int usedSessions = 6; // UI dummy
    final int remainingSessions = totalSessions - usedSessions;
    final double progress = usedSessions / totalSessions;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if(state is Unauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: MyColors.iconDark,
              onPressed: () {},
            ),
          ],
        ),

        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MyColors.backgroundStart,
                MyColors.backgroundMid,
                MyColors.backgroundEnd,
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              //  Avatar
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [MyColors.gradient1, MyColors.gradient2],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 45,
                  color: MyColors.iconLight,
                ),
              ),

              const SizedBox(height: 12),

              //  Name
              Text(
                'Sakina Kheraj',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MyColors.primaryText,
                ),
              ),

              //  Email
              Text(
                'sakina@gmail.com',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: MyColors.secondaryText,
                ),
              ),

              const SizedBox(height: 30),

              //  Usage Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MyColors.glassBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MyColors.gradient3),
                  boxShadow: const [
                    BoxShadow(color: MyColors.shadowLight, blurRadius: 14),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Daily Sessions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MyColors.primaryText,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '$usedSessions / $totalSessions',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: MyColors.gradient3,
                      ),
                    ),

                    const SizedBox(height: 14),

                    //  progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: MyColors.backgroundMid,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      MyColors.gradient1,
                                      MyColors.gradient3,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    //  Used / Remaining
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$usedSessions used',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: MyColors.primaryText,
                          ),
                        ),
                        Text(
                          '$remainingSessions remaining',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Resets at midnight',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: MyColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              //  Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

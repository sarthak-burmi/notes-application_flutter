import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/constants/timeGreeting.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:notes_app_solulab/provider/auth_provider.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';
import 'package:notes_app_solulab/screens/add_note.dart';
import 'package:notes_app_solulab/screens/notes_edit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({super.key});

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  DateTime _selectedDate = DateTime.now();
  final String _filterMode =
      "current"; // possible values: "current", "past", "future", "all"
  final List<DateTime> _dateList = [];
  bool _showAllTasks =
      false; // Toggle for showing all tasks or just selected date

  @override
  void initState() {
    super.initState();
    _generateDateList();
  }

  void _generateDateList() {
    // Generate date list starting with today and showing 10 days ahead
    final now = DateTime.now();
    _dateList.clear();

    // Add today first
    _dateList.add(now);

    // Add next 10 days in sequence
    for (int i = 1; i <= 10; i++) {
      _dateList.add(now.add(Duration(days: i)));
    }
  }

  bool _isSelectedDate(Note note) {
    if (_showAllTasks) return true; // Show all tasks regardless of date

    if (_selectedDate == null) return true;

    try {
      // Filter by task date instead of creation date
      final taskDate = DateTime.parse(note.taskDate);
      return taskDate.year == _selectedDate.year &&
          taskDate.month == _selectedDate.month &&
          taskDate.day == _selectedDate.day;
    } catch (e) {
      return false;
    }
  }

  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final height = screenSize.height;

    // Determine breakpoints
    final isSmallScreen = width < 360;
    final isMediumScreen = width >= 360 && width < 600;
    final isLargeScreen = width >= 600;

    // Adjust horizontal padding based on screen size
    final horizontalPadding = isSmallScreen
        ? width * 0.03
        : (isMediumScreen ? width * 0.05 : width * 0.07);

    final authUser = ref.watch(authUserProvider).value;
    final notesState = ref.watch(notesProvider);
    final userMetadata = ref.watch(userMetadataProvider).valueOrNull ?? {};

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    String weekday = DateFormat('EEEE').format(now);

    // Filter notes by selected date using task date
    final filteredNotes =
        notesState.notes.where((note) => _isSelectedDate(note)).toList();

    // Calculate task statistics
    final totalTasks = filteredNotes.length;
    final completedTasks =
        filteredNotes.where((note) => note.isCompleted).length;

    if (authUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (notesState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: mainColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your tasks...',
                style: GoogleFonts.montserrat(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Hub',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userMetadata['name'] != null
                              ? 'Hello, ${userMetadata['name']}!'
                              : 'Hello!',
                          style: GoogleFonts.montserrat(
                            color: Colors.black54,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        try {
                          await ref.read(authControllerProvider).signOut();
                          Fluttertoast.showToast(
                            msg: "Logged Out Successfully",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black87,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          // AuthGate will handle navigation
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "Error logging out: ${e.toString()}",
                            backgroundColor: Colors.red,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 32 : 48,
                        minHeight: isSmallScreen ? 32 : 48,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.015),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: TimeGreetingScreen()),
                ],
              ),
            ),

            // Task statistics
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        context,
                        'Total Tasks',
                        totalTasks.toString(),
                        Icons.note_alt_outlined,
                        mainColor,
                        isSmallScreen),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildStatCard(
                        context,
                        'Completed',
                        completedTasks.toString(),
                        Icons.check_circle_outline,
                        completedTask,
                        isSmallScreen),
                  ),
                ],
              ),
            ),

            // Toggle for All Tasks
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showAllTasks ? Icons.visibility : Icons.filter_list,
                        color: mainColor,
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showAllTasks ? "All Tasks" : "Date Filtered Tasks",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _showAllTasks
                                ? "Showing tasks from all dates"
                                : "Showing tasks only for selected date",
                            style: GoogleFonts.montserrat(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: isSmallScreen ? 0.8 : 1.0,
                      child: CupertinoSwitch(
                        value: _showAllTasks,
                        activeColor: mainColor,
                        onChanged: (value) {
                          setState(() {
                            _showAllTasks = value;
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Date selector
            SizedBox(height: height * 0.02),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(isSmallScreen),
                ),
              ],
            ),

            // Task list
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
                child: _buildNotesList(context, ref, filteredNotes,
                    notesState.isLoading, isSmallScreen),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _buildAddNoteButton(context, ref, authUser.id, isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
          horizontal: isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.black54,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Date selector widget
  Widget _buildDateSelector(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 80 : 90,
      padding: const EdgeInsets.only(left: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dateList.length,
        itemBuilder: (context, index) {
          final date = _dateList[index];
          final isToday = _isDateToday(date);
          final isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _showAllTasks =
                    false; // Turn off "All Tasks" when selecting a specific date
              });
            },
            child: Container(
              width: isSmallScreen
                  ? (isToday ? 65 : 55)
                  : (isToday ? 75 : 65), // Make today's card slightly wider
              margin: EdgeInsets.only(right: 8, bottom: isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? mainColor
                    : (isToday ? Colors.blue.shade50 : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? mainColor
                      : (isToday ? Colors.blue.shade300 : Colors.grey.shade300),
                  width: isToday ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: mainColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : (isToday
                        ? [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday
                        ? 'Today'
                        : DateFormat('E').format(date).substring(0, 3),
                    style: GoogleFonts.montserrat(
                      color: isSelected
                          ? Colors.white
                          : (isToday ? Colors.blue.shade700 : Colors.black54),
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.montserrat(
                        color: isSelected
                            ? mainColor
                            : (isToday ? Colors.blue.shade700 : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteItem(
      BuildContext context, WidgetRef ref, Note note, bool isSmallScreen) {
    // Format task date for display
    String formattedTaskDate = "";
    try {
      final taskDate = DateTime.parse(note.taskDate);
      formattedTaskDate = DateFormat('dd/MM/yyyy').format(taskDate);
    } catch (e) {
      // If parsing fails, try to use createdAt as fallback
      try {
        final createdDate = DateTime.parse(note.createdAt);
        formattedTaskDate = DateFormat('dd/MM/yyyy').format(createdDate);
      } catch (e) {
        formattedTaskDate = "Unknown date";
      }
    }

    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 12.0),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      _confirmDelete(context, ref, note.id);
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEdit(note: note),
                        ),
                      );
                    },
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: note.isCompleted ? Colors.grey.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    width: 1.5,
                    color: note.isCompleted
                        ? Colors.grey.shade300
                        : mainColor.withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEdit(note: note),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8 : 12,
                        horizontal: isSmallScreen ? 12 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: isSmallScreen ? 0.9 : 1.1,
                          child: Checkbox(
                            value: note.isCompleted,
                            activeColor: completedTask,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            side: BorderSide(
                              width: 1.5,
                              color: note.isCompleted
                                  ? completedTask
                                  : Colors.grey.shade400,
                            ),
                            onChanged: (bool? value) {
                              ref
                                  .read(notesProvider.notifier)
                                  .toggleNoteCompletion(note);
                            },
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: GoogleFonts.montserrat(
                                  color: note.isCompleted
                                      ? Colors.grey
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 16 : 18,
                                  decoration: note.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              Text(
                                note.content,
                                style: GoogleFonts.montserrat(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: note.isCompleted
                                      ? Colors.grey
                                      : Colors.black54,
                                  decoration: note.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              // Task date display - make responsive
                              Wrap(
                                spacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: isSmallScreen ? 10 : 12,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: isSmallScreen ? 2 : 4),
                                      Flexible(
                                        child: Text(
                                          "Task: $formattedTaskDate",
                                          style: GoogleFonts.montserrat(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: isSmallScreen ? 10 : 12,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: isSmallScreen ? 2 : 4),
                                      Flexible(
                                        child: Text(
                                          "Created: ${_getTimeAgo(note.createdAt)}",
                                          style: GoogleFonts.montserrat(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Format creation date in a human-readable way (e.g., "2 days ago")
  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago";
      } else if (difference.inDays > 30) {
        return "${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago";
      } else if (difference.inDays > 0) {
        return "${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return "Unknown";
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String noteId) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Task',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this task?',
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () {
                ref.read(notesProvider.notifier).deleteNote(noteId);
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Task deleted successfully",
                  backgroundColor: Colors.black87,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddNoteButton(
      BuildContext context, WidgetRef ref, String userId, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [mainColor, Color(0xFF8F6FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: isSmallScreen ? 46 : 56,
      height: isSmallScreen ? 46 : 56,
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddNoteScreen(),
          ),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: isSmallScreen ? 24 : 28,
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, WidgetRef ref, List<Note> notes,
      bool isLoading, bool isSmallScreen) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: mainColor),
      );
    }

    if (notes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/Oops! 404 Error with a broken robot-rafiki.png",
                height: isSmallScreen ? 150 : 200,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                _showAllTasks ? 'No tasks found' : 'No tasks for this day',
                style: GoogleFonts.montserrat(
                  color: Colors.black54,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Tap the + button to create a new task',
                style: GoogleFonts.montserrat(
                  color: Colors.black38,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildNoteItem(context, ref, note, isSmallScreen),
              ),
            ),
          );
        },
      ),
    );
  }
}

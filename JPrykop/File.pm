package JPrykop::File;

use strict;

=pod

=head1 NAME

JPrykop::File - File object for filesystem interactions and binary data

=head1 USES

	use JPrykop::Config;

=cut

use JPrykop::Config;

=pod

=head1 DESCRIPTION

THIS IS A CODE SAMPLE from one of my longer-term projects;  I've
swapped out the name of that project with JPrykop in the code below,
but otherwise made no changes.  Unfortunately I cannot release enough 
of the overall system for it to compile, I can merely assure you that 
it's been running smoothly for several years.  If given the chance to
do it again, I would make directories their own class rather than leave
them implied by the existence of the files within them.  I would also
seek further integration with os-level file lookup tools to improve
speed.  That said, this module has done a good job avoided conflicts 
and data loss when allowing both external users and other programmers 
to manipulate files on our system.  B<Thanks for your interst in my work!>
B<--Jonathan Prykop, Dec 2014>

This module is used for creating, erasing and locating data files
in the JPrykop system in a manner that is abstracted from any 
knowledge of where they are actually stored.  (Configuration for 
the storage locations occurs in JPrykop::Config.)  JPrykop::File
objects should be used by both interface and analysis programmers 
for any data files they need to work with.  The L</getSysName> method 
should then be used to locate these files dynamically, rather than 
hard-coding system path information into individual scripts.

JPrykop::File objects are also the recommended method for passing any 
large and/or binary data through the JPrykop::Analysis::Data 
object.  In addition to arrayref and strings, 
JPrykop::Analysis::Data set methods will also accept 
JPrykop::File objects as input values.

File names and paths are case-sensitive, like unix filesystems, and this
module will need adjustment before it can be run on case-insensitive filesystems.

=head2 Basic Usage

	use JPrykop::File;

	#load a file based on its $name
	$file = JPrykop::File->load_byname($name)
		if JPrykop::file->isValidName($name);
	
	#open a filehandle for reading and writing
	my $sysname = $file->getSysName();
	open(FILEHANDLE,$sysname);
	
	#remove a file completely from the system (disk & database)
	$file->erase();
	
	#see if a file has been erased
	$file->isDead();

The I<$name> of the file is relative to the top level of the directory 
in which all data is stored, including path information--the same as 
will then be returned by L</getFullName> (validated using L</isValidName>.)  
Initial slashes are optional, and I<$name> will be interpreted the same 
whether or not it begins with a slash (stored names do not include prefix slash.)

I<$content> is always optional.

In general, when a file is erased using L</erase>, the remaining File object will still 
exist in memory, but it will be "dead" and contain no data.  Most methods will generate 
a warning in the error logs and return undef.  You can use the method L</isDead> to see 
if a File object has been erased.

Once the object is created or loaded, you can access other useful
information about the file using L</getExtension>, L</getFileName>, L</getFileNameNoExtension>,
L</getMimeType> and L</getSize>.  Configuration of the file viewing system 
is not currently documented;  however, you may retrieve the URL for viewing 
a file with the L</getURL> method.

=head2 Temporary Files

	#create a temporary file
	$file = JPrykop::File->createTemp($tempname,$content)
		if JPrykop::File->isValidFileName($tempname);
	
	#get expiration time of file
	$exptime = $file->getExpirationTime();
	
	#get createTemp input name
	$tempname = $file->getTempInputName();

Temp files may be safely created by JPrykop::Data analysis programmers, and all files 
created in the course of an analysis should use L</createTemp>.  With temp files, the 
I<$tempname> that is passed to L</createTemp> must be a simple filename and cannot 
contain any additional path information (temp file structure is flat, validate using 
L</isValidFileName>.)  The name you pass will be prepended with 'temp/' and a unique 
identifier, to ensure that nothing is overwritten.  Thus, for temp files, the 
I<$tempname> that you pass into L</createTemp> will not be the same as the names you recieve 
from the L</getFullName> or L</getFileName> methods; you can use L</getTempInputName>
to find the unaltered input name.  Unless someone updated this hard-coded value 
without updating this documentation, temp files expire in 24 hours.

The expiration date is checked every time L</load_byname> is run,
and if a file is expired, it will automatically L</erase> it from
the system and return undef.

=head2 Advanced object creation methods

Most programmers should either use the L</createTemp> method or one of
the JPrykop::User methods for creating files.  This ensures that files 
will be properly secured and accounted for--every file is
either temporary or owned by a user.

For programmers that are prepared to ensure that their files are properly
maintained, the following methods are also available for creating file objects.

	#create a file
	my $newfile = JPrykop::File->create($name,$content,$expires)
		if JPrykop::File->isValidNewName($name);
	
	#move a file
	$file->move($newname);
	
	#recognize a file that's on the filesystem but not in the database
	my $file = JPrykop::File->recognize($name,$expires);
	
	#change expiration time on a file
	$file->expires($newexpires);

I<$content> and I<$expires> are always optional.  L</create> and L</move> will
create new directories as appropriate.

=head2 Filesystem and database conflicts

File objects are stored in a database, but the files themselves
are stored on the hard drive just like any other file.  Sometimes,
it's possible for the filesystem to get out of sync with the database.

If the L</create> method finds that the file already exists
on the hard drive, it will not overwrite the currently existing 
file, and it will return undef.

If the L</load_byname> method finds the file in the database but not 
on the hard drive, it will remove the file's entry in the database 
and return undef.

If the L</load_byname> method does not find the file in the database, 
it will return undef, even if the file exists on the hard drive.

If you have created/moved a file without using this module, you can use the 
L</recognize> method to properly register the file in the database.

Both L</create> and L</recognize> will overwrite any previously
existing database entries for that filename.

=head2 Directories

Directories are not themselves accessible as objects, however this module
offers a few methods which can be used to add and remove directories in the
JPrykop::File hierarchy.  To avoid confusion, all of these must be called as class
methods, and will throw an error if called as object methods.

	#list all subdirectories of a given directory (defaults to top level)
	my @subdirs = JPrykop::File->listPath($dir);
	
	#load JPrykop::File objects for an entire directory
	my @fileobjs = JPrykop::File->loadPath($dir);

	#create a new directory (can create entire tree at once)
	JPrykop::File->createPath($dir)
		if JPrykop::File->isValidNewPath($dir);

	#erase a directory, and all of its contents
	JPrykop::File->erasePath($dir);

	#see if a directory already exists
	JPrykop::File->isExistingPath($dir);

Every I<$dir> above validates using L</isValidPath>;  you can also test the
validity of individual directory names using L</isValidDirName>.

=head2 User Files

Files created by JPrykop::User will have a home directory set, and you can retrieve the
full name relative to this home directory with L</getHomeName>.  This should not be used 
as a litmus test to see if a file is owned by a user, and is only sure to be set accurately
by files that have been created or loaded with User methods.

The JPrykop::User module also makes use of hidden I<+jprykop+> files for saved analyses.
These are not recognized as valid File objects because of the plus sign in their names, but
this module is coded to gracefully ignore them instead of throwing an error.  Be careful,
however, as they will be erased by both L</erasePath> and by L</movePath>, and yet L</movePath>
will B<not> actually move them--they will simply be lost.  Thus these methods should not be
used on directories that are known to be saved analyses;  instead, use the appropriate methods
in JPrykop::User.

=head2 File Locks

	# add a lock
	my $lockid = $file->addLock();
	
	# check to see if the file contains any locks
	$file->isLocked();

	# check to see if a directory has any locks
	JPrykop::File->isLocked($path);

	# this will remove only this lock
	$file->dropLock($lockid);
	
	# this will remove all locks on the file
	$file->dropAllLocks();

	# remove all locks on a path
	JPrykop::File->dropAllLocks($path)

	# use lockcache
	my $lockcache = JPrykop::File->lockcache();
	$file->isLocked($lockcache);
	JPrykop::File->isLocked($path,$lockcache);

Locks may be added to files to prevent them from being moved or erased.  Add a lock with 
the L</addLock> method, which will return a unique I<$lockid>.  This lock can then be 
removed using L</dropLock>.  Remove all locks from a file or directory using L</dropAllLocks>.  
Locking a file will cause the methods L</move>, L</movePath>, L</erase> and L</erasePath>
to fail.  You can see if a file or directory contains any locks with L</isLocked>.

If you want to use L</isLocked> on many files in essentially the same instant (if it's
irrelevant whether or not the database changes during processing) then you can load
a cache using L</lockcache> and pass the cache to L</isLocked>.  L</isLocked> may be recursive,
and a cache will automatically be generated if one is not passed before it recurs.

=head1 METHODS

=cut

use vars qw(
	$SQL_ALL_LOCKS
	$TEMP_FILE_EXPIRATION
	$ROOT_PATH
	$URL_ROOT
	$MIMETYPES
	$SQL_CREATE_FILE
	$SQL_ERASE
	$SQL_ERASE_BYNAME
	$SQL_EXPIRES
	$SQL_GET_ALL_FILENAMES
	$SQL_HASLOCKS
	$SQL_HASLOCKS_BYNAME
	$SQL_LOAD_BYID
	$SQL_LOAD_BYNAME
	$SQL_LOCK
	$SQL_MOVE_FILE
	$SQL_SET_HOMEDIR
	$SQL_SET_TEMPNAME
	$SQL_UNLOCK
	$SQL_UNLOCK_FILE
);

$TEMP_FILE_EXPIRATION = 60*60*24;

$ROOT_PATH = JPrykop::Config->getUserDataPath() . '/';
$URL_ROOT = JPrykop::Config->getUserDataURL();
$MIMETYPES = JPrykop::Config->getMimeTypes();

=pod

=head2 addLock

Accepts optional I<$username> (used only for logging purposes.)  Adds a lock to a file, 
returns I<$lockid> for use by L</dropLock>, undef on error.  See L</File Locks>.

=cut

sub addLock {
	my $self = shift;
	my $username = shift || undef;
	if ($self->isDead()) {
		warn "Attempted to lock a dead filehandle";
		return undef;
	}
	my $file_id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_LOCK;
	my $sth = $dbh->prepare($sql) || die "Error preparing $file_id for add lock";
	$sth->execute($file_id,$username) || die "Error locking $file_id";
	$sth->finish();
	$sth = $dbh->prepare('select LAST_INSERT_ID() id');
	$sth->execute();
	my $hashref = $sth->fetchrow_hashref();
	my $lockid = undef;
	if ($hashref) {
		$lockid = $hashref->{'id'};
	} else {
		warn "Error retrieving last insert id for add lock";
	}
	$sth->finish();
	return $lockid;
}

=pod

=head2 clean

Performs a L</load_byname> for each filename found in the database, thus erasing it if it 
is past expiration or no longer exists in the system.  Returns a list of filenames deleted.

For security reasons, must be run as a class method.

=cut

sub clean {
	my $class = shift;
	die unless $class eq 'JPrykop::File';
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_GET_ALL_FILENAMES;
	my $sth = $dbh->prepare($sql) || die "Error preparing get all filenames";
	$sth->execute() || die "Error getting all filenames";
	my @out;
	while (my $hashref = $sth->fetchrow_hashref()) {
		my $filename = $hashref->{'fullname'};
		my $file = $class->load_byname($filename);
		unless (ref($file) eq $class) {
			push(@out,$filename);
		}
	}
	$sth->finish();
	return @out;
}

=pod

=head2 create

Accepts I<fullname>, optional I<content> and optional I<expires>.  I<name> is
checked for validity using an internal call to L</isValidNewName>.
I<expires> should be specified in number of seconds from now;  if it is left undefined, 
the file will never expire and must be erased by hand (using the 
L</erase> method, NOT by simply deleting from the hard drive!)  
Returns the created File object, or undef if problems occurred.

For more details see L</Advanced object creation methods>
and L</Filesystem and database conflicts>.

=cut

#creates a new file with $name using initial $content
#includes test of $name and $content validity
#$content must be non-ref string (binary and zero-value acceptable) value
#returns new object if successful
#returns undef if input was invalid, dies if db or filewriting error occurred
sub create {
	my $this = shift;
	my $class = ref($this) || $this;
	my $name = shift;
	my $content = shift || '';
	my $expires = shift;
	$name =~ s/\/\//\//g;
	$name =~ s/^\///;
	#validate data
	return undef unless $this->isValidNewName($name);
	return undef if ref($content);
	#create new path if necessary
	if ($name =~ /(.*)\//) {
		my $path = $1;
		unless ($class->isExistingPath($path)) {
			return undef unless $class->createPath($path);
		}
	}
	#create file on filesystem & recognize
	my $absname = $ROOT_PATH . $name;
	open(NEWFILE,">$absname") || die "Could not open file $absname for writing";
	print NEWFILE $content;
	close(NEWFILE);
	return $this->recognize($name,$expires);
}

=pod

=head2 createPath

Accepts I<$pathname>.  Creates path in userdata hierarchy.

Returns 1 on success, undef if path already existed or other errors.

For security reasons, may ONLY be called as an JPrykop::File class method.  

=cut

sub createPath {
	my $class = shift;
	die "File->createPath not called as class method" unless ($class eq 'JPrykop::File');
	my $subdir = shift || '';
	$subdir =~ s/\/\//\//g;
	$subdir =~ s/^\///g;
	$subdir =~ s/\/$//g;
	warn "createPath called without subdir" unless $subdir;
	return undef unless $subdir;
	warn "$subdir is not a valid new path" unless $class->isValidNewPath($subdir);
	return undef unless $class->isValidNewPath($subdir);
	my @subdirs = split(/\//,$subdir);
	my $nextsubdir = '';
	foreach my $level (@subdirs) {
		$nextsubdir .= $level . '/';
		my $rootdir = $ROOT_PATH . $nextsubdir;
		mkdir($rootdir);
		unless ($class->isExistingPath($nextsubdir)) {
			warn "mkdir appears to have failed for $rootdir";
			return undef;
		}
	}
	return 1;
}

=pod

=head2 createTemp

Accepts I<name> and I<content>.  I<name> is checked for validity 
using an internal call to L</isValidFileName>, and may not contain
additional path info.  The filename that's created will be prepended
with 'temp/' and the number of seconds since the 1960's ended, to
help encourage uniqueness.  Unless someone updated this value 
without updating this documentation, temp files expire in 24 hours.
Returns the created File object, or undef if problems occurred.

You should only use this if the temporary file you are creating needs
to persist after your script finishes running.  If you're looking to
create a temp file that unlinks immediately (ie for storing input for 
a command or executable), please use the common perl package File::Temp.

=cut

sub createTemp {
	my $this = shift;
	my $name = shift;
	my $content = shift;
	$name = '' unless defined($name);
	$name =~ s/\/\//\//g;
	$name =~ s/^\///;
	return undef unless $this->isValidFileName($name);
	my $prefix = 'temp/' . time();
	my $i = 0;
	#iterate past other recent (ie within 1 second) tempfiles
	while (!($this->isValidNewName($prefix.'_'.$i.$name))) {
		$i++;
		if ($i > 100) { #sanity check
			die "Possible infinite recursion detected, check code";
		}
	}
	my $filename = $prefix.'_'.$i.$name;
	my $out = $this->create($filename,$content,$TEMP_FILE_EXPIRATION);
	if (ref($out) eq $this) {
		my $file_id = $out->getID();
		my $dbh = JPrykop::Config->getDBH();
		my $sql = $SQL_SET_TEMPNAME;
		my $sth = $dbh->prepare($sql) || die "Error preparing $name for set tempname";
		$sth->execute($name,$file_id) || die "Error setting tempname $name";
		$sth->finish();
		$out->{'tempinputname'} = $name;
	}
	return $out;
}

=pod

=head2 dropLock

Accepts I<$lockid>.  Removes that lock from this file (will not remove unless lock
belongs to this file.)  No meaningful return value.  See L</File Locks>.

=cut

sub dropLock {
	my $self = shift;
	my $lockid = shift;
	if ($self->isDead()) {
		warn "Attempted to unlock a dead filehandle";
		return undef;
	}
	unless ($lockid =~ /^\d+$/) {
		warn "Bad lock ID $lockid sent to dropLock";
		return undef;
	}
	my $file_id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_UNLOCK;
	my $sth = $dbh->prepare($sql) || die "Error preparing lock $lockid file $file_id for drop lock";
	$sth->execute($file_id,$lockid) || die "Error dropping lock $lockid from $file_id";
	$sth->finish();
}

=pod

=head2 dropAllLocks

If run as a class method, accepts I<$fullname> which should be either a full filename or path.
If run as an object method, uses object name.  Removes all locks from file (or files contained
in directory.)  No meaningful return value.  See L</File Locks>.

=cut

sub dropAllLocks {
	my $self = shift;
	my $name = shift;
	if (ref($self)) {
		if ($self->isDead()) {
			warn "Attempted to unlock a dead filehandle";
			return undef;
		}
		my $file_id = $self->getID();
		my $dbh = JPrykop::Config->getDBH();
		my $sql = $SQL_UNLOCK_FILE;
		my $sth = $dbh->prepare($sql) || die "Error preparing file $file_id for drop locks";
		$sth->execute($file_id) || die "Error dropping locks from $file_id";
		$sth->finish();
	} else {
		my $file = $self->load_byname($name);
		return $file->dropAllLocks() if $file;
		unless ($self->isExistingPath($name)) {
			warn "dropAllLocks called with bad name $name";
			return undef;
		}
		my @files = $self->loadPath($name);
		foreach $file (@files) {
			$file->dropAllLocks();
		}
	}
}

=pod

=head2 erase

Complete erases file from the system, both hard drive and database.
Returns 1 if file no longer exists on system, 0 if it's still there, 
undef if object was locked or already dead.

=cut

sub erase {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to erase a dead filehandle";
		return undef;
	}
	if ($self->isLocked()) {
		warn "Attempted to erase a locked filehandle";
		return undef;
	}
	my $name = $self->getSysName();
	unlink($name);
	my $out = (-e $name) ? 0 : 1;
	if ($out) {
		my $file_id = $self->getID();
		my $dbh = JPrykop::Config->getDBH();
		my $sql = $SQL_ERASE;
		my $sth = $dbh->prepare($sql) || die "Error prepareing file $file_id for deletion";
		$sth->execute($file_id) || die "Error deleting file $file_id";
		$sth->finish();
		$self->_markasdead();
	}
	return $out;
}

=pod

=head2 erasePath

Accepts I<$pathname>.  Erases path in userdata hierarchy, recursively, including all files
contained within.

Returns 1 on success, 0 on error or if directory is locked.  Errors may be partial,
meaning the directory was partially erased.

For security reasons, may ONLY be called as an JPrykop::File class method.  

=cut

sub erasePath {
	my $class = shift;
	die "File->erasePath not called as class method" unless ($class eq 'JPrykop::File');
	my $subdir = shift;
	unless ($subdir) {
		warn "erasePath needs subdirectory";
		return 0;
	}
	$subdir =~ s/\/\//\//g;
	$subdir =~ s/^\///g;
	$subdir .= '/' unless $subdir =~ /\/$/;
	unless ($class->isExistingPath($subdir)) {
		warn "Error erasing $subdir: does not seem to exist";
		return 0;
	}
	if ($class->isLocked($subdir)) {
		warn "Error erasing $subdir: directory locked";
		return 0;
	}
	my $rootdir = $ROOT_PATH . $subdir;
	opendir(TOERASE,$rootdir);
	my @entries = readdir(TOERASE);
	closedir(TOERASE);
	foreach my $entry (@entries) {
		next if ($entry eq '.');
		next if ($entry eq '..');
		if (-d $rootdir.$entry) {
			$class->erasePath($subdir.$entry);
		} else {
			if ($entry =~ /^\+jprykop\+/) {
				unlink($rootdir.$entry);
			} else {
				my $fileobj = $class->load_byname($subdir.$entry);
				unless (ref($fileobj) eq 'JPrykop::File') {
					warn "Error erasing $subdir: couldn't load file object for $subdir.$entry";
				} else {
					$fileobj->erase();
					warn "Error erasing $subdir: could not erase file object " . $fileobj->getFullName() unless $fileobj->isDead();
				}
			}
		}
	}
	rmdir($rootdir);
	unless ($class->isExistingPath($subdir)) {
		return 1;
	} else {
		warn "Error erasing $subdir: rmdir appears to have failed";
		return 0;
	}
}

=pod

=head2 expires

Accepts I<expires>.  Changes the expiration time on a file.

=cut

sub expires {
	my $self = shift;
	my $expires = shift || undef;
	if ($self->isDead()) {
		warn "Attempted to change expiration on a dead filehandle";
		return undef;
	}
	#calculate expiration time
	my $exptime = undef;
	if (defined($expires)) {
		$exptime  = time() + $expires;
	}
	#update db
	my $file_id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_EXPIRES;
	my $sth = $dbh->prepare($sql) || die "Error prepareing file $file_id for expiration change";
	$sth->execute($exptime,$file_id) || die "Error changing expiration of file $file_id";
	$sth->finish();
	#update object
	$self->{'expires'} = $exptime;
	return 1;
}

=pod

=head2 getExpirationTime

Returns time of expiration in number of seconds since the 1960s ended.

=cut

sub getExpirationTime {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	return $self->{'expires'};
}

=pod

=head2 getExtension

Returns file extension

=cut

sub getExtension {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $filename = $self->getFileName();
	my $ext = $filename;
	$ext =~ s/.*\.(.*)/$1/;
	$ext = undef if ($ext eq $filename);
	return $ext;
}

=pod

=head2 getFileName

Returns the filename, without path info but with extension.

=cut

sub getFileName {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $fullname = $self->getFullName();
	my @path = split('/',$fullname);
	my $filename = $path[$#path];
	return $filename;
}

=pod

=head2 getFileNameNoExtension

Like L</getFileName> but does not include extension.

=cut

sub getFileNameNoExtension {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $filename = $self->getFileName();
	my $noext = $filename;
	$noext =~ s/(.*)\..*/$1/;
	return $noext;
}

=pod

=head2 getFullName

Returns the full name of the file, including path info relative to
the top level of the data directory.  Use L</getSysName> to get the
full path for direct access to the filesystem.

=cut

sub getFullName {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	return $self->{'fullname'};
}

=pod

=head2 getHomeName

Returns the name of the file relative to the JPrykop::User home directory.
Returns undef on error or if home dir hasn't been set by JPrykop::User.

=cut

sub getHomeName {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $homedir = $self->{'homedir'};
	return undef unless $homedir;
	my $homename = $self->getFullName();
	return undef unless ($homename =~ /^$homedir\//);
	$homename =~ s/^$homedir\///;
	return $homename;
}

sub getID {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	return $self->{'file_id'};
}

=pod

=head2 getLastUpdate

If called as an object method, operates on object file.
If called as a class method, accepts file or folder I<$name>, relative to userdata root.
Returns unix last modified timestamp, undef on error.

=cut

sub getLastUpdate {
	my $this = shift;
	my $name = shift;
	if (ref($this) eq 'JPrykop::File') {
		my @stats = $this->getStats();
		return undef unless scalar(@stats);
		return $stats[9];
	}
	$name =~ s/\/\//\//g;
	$name =~ s/^\///g;
	$name =~ s/\/$//g;
	return undef unless $name;
	return undef unless ($this->isValidName($name) || $this->isValidPath($name));
	my $sysname = $ROOT_PATH . $name;
	my @stats = stat($sysname);
	return undef unless scalar(@stats);
	return $stats[9];
}

=pod

=head2 getMimeType

Returns the Mime Type of the file, based on its extension, according to the apache defaults.

=cut

sub getMimeType {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $mimetype = undef;
	my $ext = $self->getExtension();
	if (defined($MIMETYPES->{$ext})) {
		$mimetype = $MIMETYPES->{$ext};
	}
	return $mimetype;
}

=pod

=head2 getSize

Returns the size of the file, according to a perl stat() call.

=cut

sub getSize {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $sysname = $self->getSysName();
	my @stats = stat($sysname);
	return $stats[7];
}

=pod

=head2 getStats

Returns full stat() results on file.

=cut

sub getStats {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $sysname = $self->getSysName();
	my @stats = stat($sysname);
	return @stats;
}

=pod

=head2 getSysName

Returns the full filesystem path to the file.

=cut

sub getSysName {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $sysname = $ROOT_PATH . $self->getFullName();
	return $sysname;
}

=pod

=head2 getTempInputName

Returns I<$name> originally sent to L</createTemp>.

=cut

sub getTempInputName {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	return $self->{'tempinputname'};
}

=pod

=head2 getURL

Returns the URL for retrieving the file.

=cut

sub getURL {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to retrieve information from a dead filehandle";
		return undef;
	}
	my $out = $URL_ROOT . $self->getFullName();
	return $out;
}

=pod

=head2 isContainedIn

Accepts I<$path>.  Returns 1 if file object is contained within path (including subdirs
of path), undef otherwise.  (Always returns 1 if no path is specified)

=cut

sub isContainedIn {
	my $self = shift;
	my $path = shift;
	return undef unless ref($self);
	return 1 unless $path;
	$path =~ s/\/\//\//g;
	$path =~ s/^\///g;
	$path =~ s/\/$//g;
	return undef unless JPrykop::File->isExistingPath($path);
	my $fullpath = $self->getFullName();
	$fullpath =~ s/(.*)\/.*/$1/; #strip out filename
	return undef if ($fullpath eq $self->getFullName()); #in top dir
	return 1 if $fullpath =~ /^$path$/; #in path
	return 1 if $fullpath =~ /^$path\//; #in subdir of path
	return undef;
}

=pod

=head2 isDead

Returns 1 if File object has been erased using L</erase>.  Does not 
currently perform any filesystem or database checks on its own, so
if things were somehow deleted by hand since the loading of this
object, this may be inaccurate.  But of course, that should never happen.

=cut

sub isDead {
	my $self = shift;
	return $self->{'isdead'};
}

=pod

=head2 isExistingPath

Accepts I<$path>, relative to userdata root.
Returns 1 if path already exists on file system, 0 otherwise.

For security reasons, may ONLY be called as an JPrykop::File class method.  

=cut

sub isExistingPath {
	my $class = shift;
	die "File->isExistingPath not called as class method" unless ($class eq 'JPrykop::File');
	my $subdir = shift || '';
	$subdir =~ s/\/\//\//g;
	$subdir =~ s/^\///;
	(($subdir =~ /\/$/) || ($subdir .= '/')) if $subdir;
	return 0 unless $class->isValidPath($subdir);
	my $rootdir = $ROOT_PATH . $subdir;
	return 0 unless (-d $rootdir);
	return 1;
}

=pod

=head2 isLocked

If run as a class method, accepts I<$fullname> which should be either a full filename or path.
If run as an object method, uses object name.  For files, returns 1 if file contains any
locks, 0 if not, undef on error.  For paths, returns 1 if path contains any locked files,
0 if not, undef on error.  See L</File Locks>.

Also accepts optional I<$lockcache> as generated by L</lockcache>, which can be used to save 
time when the locks on multiple files are being checked in essentially the same instant.

=cut

sub isLocked {
	my $self = shift;
	my $name = shift;
	my $lockcache = shift;
	if (!$lockcache && (ref($name) eq 'HASH')) {
		$lockcache = $name;
		$name = undef;
	}
	if (ref($self)) {
		if ($self->isDead()) {
			warn "Attempted to check locks on a dead filehandle";
			return undef;
		}
		my $file_id = $self->getID();
		if ($lockcache) {
			return 1 if $lockcache->{$file_id};
		} else {
			my $dbh = JPrykop::Config->getDBH();
			my $sql = $SQL_HASLOCKS;
			my $sth = $dbh->prepare($sql) || die "Error preparing $file_id for getlocks";
			$sth->execute($file_id) || die "Error getting locks for $file_id";
			my $firstlock = $sth->fetchrow_hashref();
			$sth->finish();
			return 1 if $firstlock;
		}
		return 0;
	} else {
		my $file = $self->load_byname($name);
		return $file->isLocked($lockcache) if $file;
		$name =~ s/\/\//\//g;
		$name =~ s/^\///;
		(($name =~ /\/$/) || ($name .= '/')) if $name;
		unless ($self->isExistingPath($name)) {
			warn "isLocked called with bad name $name";
			return undef;
		}
		my $dbh = JPrykop::Config->getDBH();
		my $sql = $SQL_HASLOCKS_BYNAME;
		my $sth = $dbh->prepare($sql) || die "Error preparing $name for getlocks";
		$sth->execute($name.'%') || die "Error getting locks for $name";
		my $firstlock = $sth->fetchrow_hashref();
		$sth->finish();
		return 1 if $firstlock;
		return 0;
	}
}

=pod

=head2 isValidDirName

Accepts I<name>.  Returns 1 if it is a valid directory name, 0 otherwise.
This will not test entire paths, only single directory names.

=cut

sub isValidDirName {
	my $self = shift;
	my $name = shift;
	return JPrykop::Config->isValidName($name);
}

=pod

=head2 isValidFileName

Accepts I<name>.  Returns 1 if it is a valid filename, 0 otherwise.

=cut

sub isValidFileName {
	my $self = shift;
	my $name = shift;
	return JPrykop::Config->isValidName($name);
}

=pod

=head2 isValidName

Accepts I<fullname>.  Returns 1 if it is a valid full path+name for a file, 0 otherwise.
Filename must be specified, does not test path alone

=cut

#Tests if full path of file $name is valid
#Filename must be specified, does not test path alone
sub isValidName {
	my $self = shift;
	my $name = shift;
	my @name = split(/\//,$name);
	my $i = 0;
	while ($i < $#name) {
		unless ($name[$i]) { #just skip blank dirs, leading / don't matter and multiple /// can be read as one
			$i += 1;
			next;
		}
		return 0 unless $self->isValidDirName($name[$i]);
		$i += 1;
	}
	return 0 unless $self->isValidFileName($name[$i]);
	return 1;
}

=pod

=head2 isValidNewName

Same as L</isValidName> except also tests if file or directory of that name already exists 
(on hard drive, not database) or if creation of additional subdirectories would confict
with existing filenames. 
Returns 0 if file exists or is otherwise invalid, 1 if it's valid.

=cut

sub isValidNewName {
	my $self = shift;
	my $class = ref($self) || $self;
	my $name = shift;
	$name =~ s/\/\//\//g;
	$name =~ s/^\///g;
	return 0 unless $self->isValidName($name);
	my $fullname = $ROOT_PATH . $name;
	return 0 if (-e $fullname);
	if ($name =~ /\//) {
		my $path = $name;
		$path =~ s/(.*)\//$1/;
		unless ($class->isExistingPath($path)) {
			return 0 unless $class->isValidNewPath($path);
		}
	}
	return 1;
}

=pod

=head2 isValidNewPath

Same as L</isValidPath> except also tests if a directory of that name already exists 
(on hard drive, not database) or if directory creation would conflict with a current
filename.  Returns 0 if file exists or is otherwise invalid, 1 if it's valid.

Can only be called as class method.

=cut

sub isValidNewPath {
	my $class = shift;
	die "File->isValidNewPath not called as class method" unless ($class eq 'JPrykop::File');
	my $name = shift;
	$name =~ s/\/\//\//g;
	$name =~ s/^\///g;
	$name =~ s/\/$//g;
	return 0 if $class->isExistingPath($name);
	my @subdirs = split(/\//,$name);
	my $currdir = '';
	foreach my $subdir (@subdirs) {
		$currdir .= '/' if $currdir;
		$currdir .= $subdir;
		return 0 unless $class->isValidPath($currdir);
		next if $class->isExistingPath($currdir);
		my $fullname = $ROOT_PATH . $currdir;
		return 0 if (-e $fullname);
	}
	return 1;
}

=pod

=head2 isValidPath

Accepts I<$path>.  Returns 1 if it is a valid path, 0 otherwise.
Filenames should not be specified;  this validator will interpret them as directory names.

For security reasons, may ONLY be called as an JPrykop::File class method.  

=cut

sub isValidPath {
	my $self = shift;
	my $name = shift;
	my @name = split(/\//,$name);
	my $i = 0;
	while ($i <= $#name) {
		unless ($name[$i]) { #just skip blank dirs, leading / don't matter and multiple /// can be read as one
			$i += 1;
			next;
		}
		return 0 unless $self->isValidDirName($name[$i]);
		$i += 1;
	}
	return 1;
}

=pod

=head2 load_byname

Accepts I<fullname>.  Return data object for I<fullname> if successful,
undef otherwise.  Performs an existence and expiration check before
returning.  For more details see L</Filesystem and database conflicts>.

=cut

sub load_byname {
	my $this = shift;
	my $name = shift;
	$name =~ s/\/\//\//g;
	$name =~ s/^\///;
	my $class = ref($this) || $this;
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_LOAD_BYNAME;
	my $sth = $dbh->prepare($sql) || die "Error prepareing $name for retrieval";
	$sth->execute($name) || die "Error retrieving $name";
	my $hashref = $sth->fetchrow_hashref();
	$sth->finish();
	return undef unless $hashref;
	return _load_byhashref($hashref);
}

=pod

=head2 lockcache

For use with L</isLocked>, captures all the locks at a single moment in time,
to avoid repetative database calls when many files are being checked for locks at once.

=cut

sub lockcache {
	my $self = shift;
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_ALL_LOCKS;
	my $sth = $dbh->prepare($sql) || die "Error preparing to retrieve file locks";
	$sth->execute() || die "Error retrieving file locks";
	my $lockcache = {};
	while (my $somelock = $sth->fetchrow_hashref()) {
		my $id = $somelock->{'file_id'};
		$lockcache->{$id} = 1;
	}
	return $lockcache;
}

=pod

=head2 listPaths

Accepts optional relative I<$subdir> (defaults to top level) and optional I<$norecurse>
flag (defaults to false.)  Returns an array of subdirs, not including suffix or prefix slash, 
recursive through all levels (unless I<$norecurse> flag is set.)
Returns empty array if no subdirs are found.

For security reasons, may ONLY be called as an JPrykop::File class method.  

=cut

sub listPaths {
	my $class = shift;
	die "File->listPaths not called as class method" unless ($class eq 'JPrykop::File');
	my $subdir = shift || '';
	my $norecurse = shift || 0;
	$subdir =~ s/\/\//\//g;
	$subdir =~ s/^\///g;
	$subdir =~ s/\/$//g;
	return () unless $class->isExistingPath($subdir);
	my $rootdir = $ROOT_PATH . $subdir . '/';
	my $command = 'find "' . $rootdir . '" -mindepth 1';
	$command .= ' -maxdepth 1' if $norecurse;
	$command .= ' -type d';
	my @paths = split(/\n/,`$command`);
	for (my $i = 0; $i < scalar(@paths); $i++) {
		$paths[$i] =~ s/^$ROOT_PATH//;
	}
	return @paths;
}

=pod

=head2 loadPath

Accepts optional relative I<$subdir> (defaults to top level) and optional I<$norecurse> flag
(defaults to false.)  Loads an object for each file found there (recursive through subdirs
unless I<$norecurse> is true), thus erasing them if they're past their expiration.
Will also L</recognize> files not found in database, 
thus serving on the whole as an effective way to clean up the directory.

Caution: will not see or clean database entries for files that no longer exist on system.

Returns array of loaded file objects, or undef on error.

For security reasons, may ONLY be called as an JPrykop::File class method.  
Use L</load_byname> to load individual files.

=cut

sub loadPath {
	my $class = shift;
	die "File->loadPath not called as class method" unless ($class eq 'JPrykop::File');
	my $subdir = shift || '';
	my $norecurse = shift || 0;
	$subdir =~ s/\/\//\//g;
	$subdir =~ s/^\///;
	(($subdir =~ /\/$/) || ($subdir .= '/')) if $subdir;
	unless ($class->isExistingPath($subdir)) {
		warn "Unrecognized path $subdir in File loadPath";
		return undef;
	}
	my $rootdir = $ROOT_PATH . $subdir;
	opendir(TOCLEAN,$rootdir);
	my @entries = readdir(TOCLEAN);
	closedir(TOCLEAN);
	my @out = ();
	foreach my $entry (@entries) {
		next if ($entry eq '.');
		next if ($entry eq '..');
		if (-d $rootdir.$entry) {
			unless ($norecurse) {
				my @nextbatch = $class->loadPath($subdir.$entry);
				if (scalar(@nextbatch)) {
					push(@out,@nextbatch);
				}
			}
		} else {
			next if ($entry =~ /^\+jprykop\+/);
			my $fileobj = $class->load_byname($subdir.$entry);
			$fileobj = $class->recognize($subdir.$entry) unless $fileobj;
			push(@out,$fileobj) if $fileobj;
		}
	}
	return @out;
}

=pod

=head2 move

Accepts I<$newname>.  Checks I<$newname> with L</isValidNewName>, returning undef if
invalid.  Runs L</reload>, then moves file to I<$newname>, updating the database while 
retaining internal ID.  Returns undef on error, 1 on success.

=cut

sub move {
	my $self = shift;
	my $class = ref($self);
	my $newname = shift;
	$newname =~ s/\/\//\//g;
	$newname =~ s/^\///g;
	return undef unless $self->isValidNewName($newname);
	my $newsysname = $ROOT_PATH . $newname;
	$self->reload();
	if ($self->isDead()) {
		warn "Attempted to move a dead filehandle";
		return undef;
	}
	if ($self->isLocked()) {
		warn "Attempted to move a locked filehandle";
		return undef;
	}
	my $oldsysname = $self->getSysName();
	#create new path if necessary
	if ($newname =~ /(.*)\//) {
		my $newpath = $1;
		unless ($class->isExistingPath($newpath)) {
			return undef unless $class->createPath($newpath);
		}
	}
	#move physical file
	rename($oldsysname,$newsysname);
	die "Error moving file $oldsysname to $newsysname, old file still exists" if (-e $oldsysname);
	die "Error moving file $oldsysname to $newsysname, new file doesn't exist, file potentially lost" unless (-e $newsysname);
	#update database
	my $file_id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_MOVE_FILE;
	my $sth = $dbh->prepare($sql) || die "Error preparing move file $newname for storage";
	$sth->execute($newname,$file_id) || die "Error storing moved file $newname";
	$sth->finish();
	#update object
	$self->{'fullname'} = $newname;
	#check if home dir is still valid
	my $homedir = $self->{'homedir'};
	$self->setHomeDir($homedir) || $self->setHomeDir();
	return 1;
}

=pod

=head2 movePath

Accepts I<$oldpath> and I<$newpath>.  Moves entire contents of old to new.  New path may
be an existing path, but method will error out rather than overwrite a file.  B<Caution:>
will not move hidden I<+jprykop+> files;  these files will simply be deleted.

Returns 1 if I<$oldpath> is successfully erased, undef on error.  Operation may error out
half way through, so watch out for half-moved directories.

=cut

sub movePath {
	my $class = shift;
	die "File->movePath not called as class method" unless ($class eq 'JPrykop::File');
	my $oldpath = shift;
	my $newpath = shift || '';
	$oldpath =~ s/\/\//\//g;
	$oldpath =~ s/^\///;
	$oldpath =~ s/\/$//;
	return undef unless $class->isExistingPath($oldpath);
	if ($class->isLocked($oldpath)) {
		warn "Error erasing $oldpath: directory locked";
		return undef;
	}
	$newpath =~ s/\/\//\//g;
	$newpath =~ s/^\///;
	$newpath =~ s/\/$//;
	return undef unless $class->isValidPath($newpath);
	return undef if (($newpath =~ /^$oldpath\//) || ($newpath eq $oldpath)); #can't move a dir inside itself
	unless ($class->isExistingPath($newpath)) {
		return undef unless $class->createPath($newpath);
	}
	my @files = $class->loadPath($oldpath);
	foreach my $file (@files) {
		my $newname = $file->getFullName();
		$newname =~ s/^$oldpath/$newpath/;
		unless ($file->move($newname)) {
			warn "Error moving file to $newname";
			return undef;
		}
		unless ($file->getFullName() eq $newname) {
			warn "File not moved to $newname";
			return undef;
		}
	}
	return $class->erasePath($oldpath);
}
	

=pod

=head2 recognize

Accepts I<fullname> and optional I<expires>.  Works like L</create>, except
that it expects the file to already exist on the hard drive.  Returns
data object on success, undef on failure.  For more details see L</Advanced object creation methods>
and L</Filesystem and database conflicts>.

=cut

sub recognize {
	my $this = shift;
	my $fullname = shift;
	my $expires = shift;
	$fullname =~ s/\/\//\//g;
	$fullname =~ s/^\///;
	my $class = ref($this) || $this;
	return undef unless $this->isValidName($fullname);
	my $sysname = $ROOT_PATH . $fullname;
	return undef unless (-f $sysname);
	#calculate expiration time
	my $exptime = undef;
	if (defined($expires)) {
		$exptime  = time() + $expires;
	}
	#clear out old entry in the database
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_ERASE_BYNAME;
	my $sth = $dbh->prepare($sql) || die "Error preparing file $fullname cleanup";
	$sth->execute($fullname) || die "Error cleaning up file $fullname";
	$sth->finish();
	#save to database
	$sql = $SQL_CREATE_FILE;
	$sth = $dbh->prepare($sql) || die "Error preparing new file for storage";
	$sth->execute($fullname,$exptime) || die "Error storing new file";
	$sth->finish();
	$sth = $dbh->prepare('select LAST_INSERT_ID() id');
	$sth->execute();
	my $hashref = $sth->fetchrow_hashref();
	my $file_id = undef;
	if ($hashref) {
		$file_id = $hashref->{'id'};
	} else {
		die "Error retrieving last insert id";
	}
	$sth->finish();
	#construct object & return
	die "Error retrieving last insert id" unless $file_id;
	my $self = {
		'file_id' => $file_id,
		'fullname' => $fullname,
		'expires' => $exptime,
		'isdead' => 0
	};
	bless $self, $class;
	return $self;
}

=pod

=head2 reload

Reloads the object from the database based on its internal ID rather than its file path,
thus detecting if the file has been moved or erased.  This should be used immediately 
after an object has been retrieved from long term storage (frozen in a database or file, 
for instance) or any time another process may have moved the file.  Also performs the
existence and expiration checks associated with L</load_byname>.  If old file id doesn't
exist in database, marks the object as dead even if a file of the same filename exists on
the system.  Returns JPrykop::File object or undef.

=cut

sub reload {
	my $self = shift;
	if ($self->isDead()) {
		warn "Attempted to reload a dead filehandle";
		return undef;
	}
	my $id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_LOAD_BYID;
	my $sth = $dbh->prepare($sql) || die "Error prepareing $id for retrieval";
	$sth->execute($id) || die "Error retrieving $id";
	my $hashref = $sth->fetchrow_hashref();
	$sth->finish();
	unless ($hashref) {
		$self->_markasdead();
		return undef;
	}
	return $self->_load_byhashref($hashref);
}

#unpublished--only for use by internal here or in JPrykop::User
#
#=pod
#
#=head2 setHomeDir
#
#Accepts path I<$homedir>, which must be a portion of the start of the file's L</getFullName>.
#This will be the portion of the full name ignored when the object returns L</getHomeName>.
#Returns 1 on success, undef on error.  Fails without overwriting if file is not actually
#in I<$homedir>, so may also be used as a litmus test.
#
#=cut

sub setHomeDir {
	my $self = shift;
	my $homedir = shift || undef;
	if (defined($homedir)) {
		$homedir =~ s/^\///g;
		$homedir =~ s/\/$//g;
		my $fullname = $self->getFullName();
		return undef unless ($fullname =~ /^$homedir\//);
	}
	my $file_id = $self->getID();
	my $dbh = JPrykop::Config->getDBH();
	my $sql = $SQL_SET_HOMEDIR;
	my $sth = $dbh->prepare($sql) || die "Error preparing $homedir for set homedir";
	$sth->execute($homedir,$file_id) || die "Error setting homedir $homedir ";
	$sth->finish();
	$self->{'homedir'} = $homedir;
	return 1;
}

#If used as method, overwrites current object, otherwise returns new object 
#accepts select * fetchrow_hashref from files table
#performs expiration check
#returns file object, undef if file expired or doesn't exist on filesystem 
sub _load_byhashref {
	my $hashref = shift;
	my $self = {};
	if (ref($hashref) eq 'JPrykop::File') {
		$self = $hashref;
		$hashref = shift;
	} else {
		bless $self;
	}
	die '_load_byhashref needs hashref input' unless ref($hashref) eq 'HASH';
	$self->{'file_id'} = $hashref->{'file_id'};
	$self->{'fullname'} = $hashref->{'fullname'};
	$self->{'expires'} = $hashref->{'expires'};
	$self->{'tempinputname'} = $hashref->{'tempname'};
	$self->{'homedir'} = $hashref->{'homedir'};
	$self->{'isdead'} = 0;
	my $sysname = $self->getSysName();
	my $fullname = $self->{'fullname'};
	unless (-f $sysname) {
		warn "Could not detect loaded file $fullname on filesystem, erasing";
		$self->erase();
		return undef;
	}
	if ($self->getExpirationTime()) {
		if ($self->getExpirationTime() < time()) {
			warn "Loaded file $fullname has expired, erasing";
			$self->erase();
			return undef;
		}
	}
	return $self;
}

sub _markasdead {
	my $self = shift;
	$self->{'file_id'} = undef;
	$self->{'fullname'} = undef;
	$self->{'expires'} = undef;
	$self->{'tempinputname'} = undef;
	$self->{'homedir'} = undef;
	$self->{'isdead'} = 1;
}

$SQL_ALL_LOCKS = <<EOF;
select distinct file_id from filelocks
EOF

$SQL_CREATE_FILE = <<EOF;
insert into files set
	file_id = 0,
	fullname = ?,
	expires = ?
EOF

$SQL_MOVE_FILE = <<EOF;
update files set
	fullname = ?
where
	file_id = ?
EOF

$SQL_ERASE = <<EOF;
delete from files
where file_id = ?
EOF

$SQL_ERASE_BYNAME = <<EOF;
delete from files
where fullname = ?
EOF

$SQL_EXPIRES = <<EOF;
update files set
	expires = ?
where
	file_id = ?
EOF

$SQL_GET_ALL_FILENAMES = <<EOF;
select fullname from files;
EOF

$SQL_HASLOCKS = <<EOF;
select * from filelocks
where file_id = ?
limit 1
EOF

$SQL_HASLOCKS_BYNAME = <<EOF;
select f.fullname
from filelocks as l, files as f 
where l.file_id = f.file_id 
and f.fullname like ?
limit 1
EOF

$SQL_LOAD_BYID = <<EOF;
select * from files
where file_id = ?
EOF

$SQL_LOAD_BYNAME = <<EOF;
select * from files
where fullname = ?
EOF

$SQL_LOCK = <<EOF;
insert into filelocks set
	lock_id = 0,
	file_id = ?,
	username = ?
EOF

$SQL_SET_HOMEDIR = <<EOF;
update files set
	homedir = ?
where
	file_id = ?
EOF

$SQL_SET_TEMPNAME = <<EOF;
update files set
	tempname = ?
where
	file_id = ?
EOF

$SQL_UNLOCK = <<EOF;
delete from filelocks
where file_id = ?
and lock_id = ?
EOF

$SQL_UNLOCK_FILE = <<EOF;
delete from filelocks
where file_id = ?
EOF

1;

__END__

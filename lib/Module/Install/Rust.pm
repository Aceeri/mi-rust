package Module::Install::Rust;

use 5.006;
use strict;
use warnings;

use Module::Install::Base;
use TOML 0.97 ();
use Config ();

our @ISA = qw( Module::Install::Base );

=head1 NAME

Module::Install::Rust - Helpers to build Perl extensions written in Rust

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    # In Makefile.PL
    use inc::Module::Install;

    # ...

    rust_requires libc => "0.2";
    rust_write;

    WriteAll;

=head1 DESCRIPTION

This package allows L<Module::Install> to build Perl extensions written in Rust.

=head1 COMMANDS

=head2 rust_write

    rust_write;

Sets up Makefile options as needed.

=cut

sub rust_write {
    my $self = shift;

    $self->rust_setup_makefile;
}

sub _rust_crate_name {
    lc shift->name
}

sub _rust_target_name {
    shift->_rust_crate_name =~ s/-/_/gr
}

sub rust_setup_makefile {
    my $self = shift;
    my $class = ref $self;

    # FIXME: don't assume libraries have "lib" prefix
    my $libname = "lib" . $self->_rust_target_name;

    my $rustc_opts = "";
    my $postproc;
    if ($^O eq "darwin") {
        # Linker flag to allow bundle to use symbols from the parent process.
        $rustc_opts = "-C link-args='-undefined dynamic_lookup'";

        # On darwin, Perl uses special darwin-specific format for loadable
        # modules. Normally it is produced by passing "-bundle" flag to the
        # linker, but Rust as of 1.12 does not support that.
        #
        # "-C link-args=-bundle" doesn't work, because then "-bundle" conflicts
        # with "-dylib" option used by rustc.
        #
        # However, it seems possible to produce correct ".bundle" file by
        # running linker with correct options on the shared library that was
        # created by rustc.
        $postproc = <<MAKE;
	\$(LD) \$(LDDLFLAGS) -o \$@ \$<
MAKE
    } else {
        $postproc = <<MAKE;
	\$(CP) \$< \$@
MAKE
    }

    $self->postamble(<<MAKE);
# --- $class section:

INST_RUSTDYLIB = \$(INST_ARCHAUTODIR)/\$(DLBASE).\$(DLEXT)
RUST_TARGETDIR = target/release
RUST_DYLIB = \$(RUST_TARGETDIR)/$libname.\$(SO)

# Dynamically link rust library.
dynamic :: \$(INST_RUSTDYLIB)

# Copy dylibs from rust build directory to where perl will see it.
\$(INST_RUSTDYLIB): \$(RUST_DYLIB)
$postproc
MAKE
}

=head1 AUTHOR

Vickenty Fesunov, C<< <kent at setattr.net> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/vickenty/mi-rust>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Vickenty Fesunov.

This module may be used, modified, and distributed under the same terms as Perl
itself. Please see the license that came with your Perl distribution for
details.

=cut

1;

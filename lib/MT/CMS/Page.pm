# Movable Type (r) Open Source (C) 2001-2010 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$
package MT::CMS::Page;

use strict;
use MT::CMS::Entry;

sub edit {
    require MT::CMS::Entry;
    MT::CMS::Entry::edit(@_);
}
sub list {
    my $app = shift;
    $app->param( 'type', 'page' );
    return $app->forward('list_entry', { type => 'page' } );
}

sub save_pages {
    my $app = shift;
    return $app->forward('save_entries');
}

sub can_view {
    my ( $eh, $app, $id, $objp ) = @_;
    $app->can_do('open_page_edit_screen');
}

sub can_delete {
    my ( $eh, $app, $obj ) = @_;
    my $author = $app->user;
    return 1 if $author->is_superuser();
    my $perms = $app->permissions;
    if ( !$perms || $perms->blog_id != $obj->blog_id ) {
        $perms ||= $author->permissions( $obj->blog_id );
    }
    return $perms && $perms->can_do('delete_page');
}

sub pre_save {
    require MT::CMS::Entry;
    MT::CMS::Entry::pre_save(@_);
}

sub post_save {
    require MT::CMS::Entry;
    MT::CMS::Entry::post_save(@_);
}

sub CMSPostSave_page {
    require MT::CMS::Entry;
    MT::CMS::Entry::post_save(@_);
}

sub cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;

    my $user = $app->user;
    return if $user->is_superuser;

    my $blog_id = $app->param('blog_id') || 0;
    my $blog = $blog_id ? $app->blog : undef;
    my $blog_ids = !$blog         ? undef
                 : $blog->is_blog ? [ $blog_id ]
                 :                  [ map { $_->id } @{$blog->blogs} ];

    require MT::Permission;
    my $iter = MT::Permission->load_iter(
        {
            author_id => $user->id,
            ( $blog_ids ? ( blog_id => $blog_ids ) : ( blog_id => { 'not' => 0 } ) ),
        }
    );

    my $filters;
    while ( my $perm = $iter->() ) {
        if ( $perm->can_do('manage_pages') ) {
            push @$filters, ( '-or', { blog_id => $perm->blog_id } );
        }
    }

    my $terms = $load_options->{terms} || {};
    delete $terms->{blog_id}
        if exists $terms->{blog_id};

    my $new_terms;
    push @$new_terms, ( $terms )
        if ( keys %$terms );
    push @$new_terms, ( '-and', $filters );
    $load_options->{terms} = $new_terms;
}

1;
